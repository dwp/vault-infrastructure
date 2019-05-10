#!/bin/sh
set -a
source /vault/server_details
source /consul/server_details

#Turning off core dump as per the guide
ulimit -c 0

CURL="curl --capath ${ca_path}"
  #Sleep for 30 seconds to make sure vault is started
  sleep 30
  while :
  do
    init_status=`$CURL -X GET $VAULT_ADDR/v1/sys/init`
    if [[ $init_status != "" ]]; then
      break
    fi
    sleep 2
  done
  # Do all the creations in the First initialised Vault Server
  if [[ $init_status = "{\"initialized\":false}" ]]; then
    secret_shares=`ls ${vault_data_path}/*.gpg | wc -l`
    $CURL -X PUT \
    --header "Content-Type: application/json" \
    --data \
    "{
      \"secret_shares\": 1,
      \"secret_threshold\": 1,
      \"stored_shares\": 1,
      \"recovery_shares\": $secret_shares,
      \"recovery_threshold\": ${secret_threshold}
    }" $VAULT_ADDR/v1/sys/init | tee /tmp/keys.json
    # Get the initial set of unseal keys to reinitiate it
    count=0
    unseal_keys=""
    while [[ $count -lt $secret_shares ]]
    do
      unseal_key=`cat /tmp/keys.json | jq -r .recovery_keys[$count]`
      if [[ $count -eq 0 ]]; then
        unseal_keys="$unseal_key"
      else
        unseal_keys="$unseal_keys,$unseal_key"
      fi
      count=`expr $count + 1`
    done

    #Get the initial root token
    root_token=`cat /tmp/keys.json | jq -r .root_token`
    rm /tmp/keys.json

  #Check if vault is still sealed
  count=10
  while [[ $count -gt 0 ]];
  do
    $CURL -X GET $VAULT_ADDR/v1/sys/seal-status | tee /tmp/seal_status
    seal_status=`cat /tmp/seal_status | jq -r '.sealed'`
    if [[ $seal_status = "false" ]]; then
      echo "Vault is unsealed"
      rm /tmp/seal_status
      break
    fi
      echo "Vault is still sealed. Checking after 2 secs..... Check $count"
      sleep 2
      count=`expr $count - 1`
      rm /tmp/seal_status
  done
  if [[ ${vault_license} = "enterprise" ]]; then
    $CURL -X PUT \
       --header "X-Vault-Token: $root_token" --header "Content-Type: application/json" \
       --data \
       '{
         \"text\": \"${vault_license_number}\"
       }' $VAULT_ADDR/v1/sys/license
   fi
  export VAULT_TOKEN=$root_token
  echo "Enabling Audit Method"
  vault audit enable file file_path="${vault_audit_log_file_path}"

  echo "Enabling ldap auth method"
  vault auth enable -path=auth-ldap-${vault_auth_ldap_name} ldap
  vault auth tune -default-lease-ttl=${vault_ldap_default_ttl} -max-lease-ttl=${vault_ldap_max_ttl} auth-ldap-${vault_auth_ldap_name}/

  echo "Configuring the LDAP Login Method"
  vault write auth/auth-ldap-${vault_auth_ldap_name}/config url=${vault_ldap_name} case_sensitive_names=true starttls=${vault_ldap_starttls} binddn=${vault_ldap_binddn} bindpass=${vault_ldap_bindpassword} userdn=${vault_ldap_userdn} groupdn=${vault_ldap_groupdn} userattr=${vault_ldap_userattr} certificate=@${ca_file}

  decoded_default_ldap_group_maps=`echo ${default_ldap_group_maps} | tr -d '[' | tr -d ']' | tr ',' ' '`
  no_of_names=`echo $decoded_default_ldap_group_maps | wc -w`
  count=1
  while [[ $count -le $no_of_names ]];
  do
    ldap_group=`echo $decoded_default_ldap_group_maps | cut -d " " -f $count | cut -d ":" -f1`
    acl_policy=`echo $decoded_default_ldap_group_maps | cut -d " " -f $count | cut -d ":" -f2`
    echo "Updating Ldap group $ldap_group for the policy $acl_policy"
    vault write auth/auth-ldap-${vault_auth_ldap_name}/groups/$ldap_group policies=$acl_policy
    count=`expr $count + 1`
   done
   decoded_policy_names=`echo ${policy_names} | tr -d '[' | tr -d ']' | tr ',' ' '`
  chown -R ${vault_user_name}:${vault_group_name} ${vault_config_path}
  chown -R ${vault_user_name}:${vault_group_name} ${vault_data_path}
  for i in $decoded_policy_names
  do
  vault policy write $i /vault/data/$i.hcl
  done
  # Configure Token Roles
  decoded_token_role_maps=`echo ${token_role_maps} | tr -d '[' | tr -d ']' | tr ',' ' '`

  no_of_names=`echo $decoded_token_role_maps | wc -w`
  count=1
  while [[ $count -le $no_of_names ]];
  do
    token_role=`echo $decoded_token_role_maps | cut -d " " -f $count | cut -d ":" -f1`
    token_policy=`echo $decoded_token_role_maps | cut -d " " -f $count | cut -d ":" -f2`
    echo "Updating Token Role $token_role for the policy $token_policy"
    vault write auth/token/roles/$token_role role_name=$token_role allowed_policies=$token_policy disallowed_policies=${disallowed_policies_in_token_role} orphan=${token_role_orphan_status} renewable=${token_role_renewable_status}
    count=`expr $count + 1`
   done
   echo "Creating a New Project Role and Remove Project Token Role"
   vault write auth/token/roles/new-project-role role_name=new-project-role allowed_policies=${new_project_policies} disallowed_policies=${disallowed_policies_in_token_role} orphan=${token_role_orphan_status} renewable=${token_role_renewable_status}
   vault write auth/token/roles/delete-project-role role_name=delete-project-role allowed_policies=${delete_project_policies} disallowed_policies=${disallowed_policies_in_token_role} orphan=${token_role_orphan_status} renewable=${token_role_renewable_status}
   # Rekey the Vault Unseal Keys
   gpg_keys=""
   for i in `ls ${vault_data_path}/*.gpg`
   do
     if [[ $gpg_keys = "" ]]; then
       gpg_keys="$i"
     else
       gpg_keys="$gpg_keys,$i"
     fi
   done
   echo "Issuing the Rekey command"
   vault operator rekey -target=recovery -init -key-shares=$secret_shares -key-threshold=${secret_threshold} -pgp-keys="$gpg_keys" -backup
   #Removed Content here
   init_rekey_url="$VAULT_ADDR/v1/sys/rekey-recovery-key/init"
   update_rekey_url="$VAULT_ADDR/v1/sys/rekey-recovery-key/update"
   # Removed Content here
   nonce=$($CURL -X GET --header "X-Vault-Token: $root_token" $init_rekey_url | jq -r '.nonce')
   count=0
   while [[ $count -lt ${secret_threshold} ]];
   do
     cut_number=`expr $count + 1`
     unseal_key=$(echo $unseal_keys | cut -d "," -f $cut_number)
       $CURL -X PUT --header "Content-Type: application/json" \
       --data \
       "{
         \"key\": \"$unseal_key\",
         \"nonce\": \"$nonce\"
       }" $update_rekey_url | tee /tmp/new_keys.json
     count=`expr $count + 1`
   done
   # Update the Recovery Keys to SSM ,as backup is not happening
   aws s3 cp /tmp/new_keys.json s3://${backup_bucket_name}/recovery_backup_keys.json
   # Update the Consul Management Token for Consul Backend
   export CONSUL_HTTP_TOKEN=${master_uuid}
   consul acl token list | tee /tmp/all_tokens
   found="no"
   while [[ $found = "no" ]];
   do
     while IFS='' read -r line || [[ -n "$line" ]]; do
         part1=$(echo $line | awk -F ":" '{print $1}' | xargs)
         part2=$(echo $line | awk -F ":" '{print $2}'| xargs)
         if [[ $part1 = "AccessorID" ]]; then
            search_id=$part2
         fi
         if [[ $part1 = "Description" ]]; then
           if [[ $part2 = "Consul Management Token" ]]; then
             echo "INFO: Found the Consul Management token"
             found="yes"
             break
           fi
         fi
     done < /tmp/all_tokens
     consul acl token list | tee /tmp/all_tokens
   done
   rm /tmp/all_tokens
   consul acl token read -id $search_id | tee /tmp/mgmt_token
   mgmt_token=$(cat /tmp/mgmt_token | grep SecretID | awk '{print $2}')
   vault secrets enable -path=/secrets-consul-${dc_name} consul
   vault write /secrets-consul-${dc_name}/config/access address="$CONSUL_HTTP_ADDR" scheme="${consul_agent_connection_method}" token=$mgmt_token
   rm /tmp/mgmt_token
   rm /tmp/new_keys.json
   echo "INFO: Create the Vault Int CA Backend. Configuration to be done later"
   vault secrets enable -path=/secrets-pki-int-ca pki
   echo "INFO: Create the Infra Secrets Path"
   vault secrets enable -path=/secrets-infra kv
   #Delete the root token
   vault token revoke $root_token
fi

rm -rf ${vault_data_path}

echo "Putting the Audit Log in Rotation"
cat >/etc/logrotate.d/vault <<EOF
${vault_audit_log_file_path} {
    missingok
    daily
    rotate 7
    compress
    delaycompress
    copytruncate
}
EOF
semanage fcontext -a -t syslogd_var_lib_t /vault/log
restorecon -R -v /vault/log
/usr/sbin/logrotate /etc/logrotate.conf
