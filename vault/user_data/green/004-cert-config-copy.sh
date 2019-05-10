#!/bin/bash
cat > ${consul_config_path}/${consul_config_name} <<EOF
${consul_config}
EOF
cat > ${vault_config_path}/${vault_config_name} <<EOF
${vault_config}
EOF

node_ip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
sed -i -e "s/{consul_node_ip}/$node_ip/g" ${consul_config_path}/${consul_config_name}
sed -i -e "s/{node_ip}/$node_ip/g" ${vault_config_path}/${vault_config_name}

# Get the Vault Backent and Consul Agent Token
export CONSUL_HTTP_TOKEN=${master_uuid}
export CONSUL_HTTP_ADDR="${consul_server_name}:${consul_https_port}"
export CONSUL_HTTP_SSL="true"
export CONSUL_HTTP_SSL_VERIFY="true"
export CONSUL_CAPATH="${ca_path}"
export CONSUL_CLIENT_CERT="${vault_ssl_path}/${consul_client_cert_name}"
export CONSUL_CLIENT_KEY="${vault_ssl_path}/${consul_client_key_name}"

echo "INFO: Creating a Agent Token"
consul acl token create -description $HOSTNAME -policy-name "consul-agent-policy" | tee /tmp/agent_token
agent_token=$(cat /tmp/agent_token | grep SecretID | awk '{print $2}')
cat >${consul_config_path}/consul-tokens.json <<EOF
{
  "acl": {
    "tokens": {
        "agent": "$agent_token"
    }
  }
}
EOF
rm /tmp/agent_token

echo "INFO: Getting the Vault Access Token"
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
        if [[ $part2 = "Vault Access Token" ]]; then
          echo "INFO: Found the Vault Access Token"
          found="yes"
          break
        fi
      fi
  done < /tmp/all_tokens
  consul acl token list | tee /tmp/all_tokens
done
rm /tmp/all_tokens
echo "INFO: Setting the Replication Token"
consul acl token read -id $search_id | tee /tmp/access_token
access_token=$(cat /tmp/access_token | grep SecretID | awk '{print $2}')
sed -i -e "s/{vault_storage_backend_token}/$access_token/g" ${vault_config_path}/${vault_config_name}
rm /tmp/access_token

mount_points="${mount_points}"
decoded_mount_points=`echo $mount_points | tr -d '[' | tr -d ']' | tr ',' ' '`
for i in $decoded_mount_points
do
  if [[ $i = "/consul" ]]; then
    chown -R ${consul_user_name}:${consul_group_name} $i
  else
    chown -R ${vault_user_name}:${vault_group_name} $i
  fi
done
