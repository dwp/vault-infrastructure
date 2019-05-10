#!/bin/sh
set -a

restore_bucket="${restore_bucket_path}"
restore_from_backup="${restore_from_backup}"

source /consul/server_details

TOKEN=$(cat /consul/config/consul-config.json | jq -r .acl.tokens.master)
export CONSUL_HTTP_TOKEN=$TOKEN
hostname=$HOSTNAME

consul operator raft list-peers | grep -i leader
exit_code=$?

#Wait till you get a leader
while [[ $exit_code -ne 0 ]];
do
  sleep 5
  consul operator raft list-peers | grep -i leader
  exit_code=$?
done

consul operator raft list-peers | grep -i leader | grep $hostname
exit_code=$?

cat > /tmp/consul-agent-policy <<EOF
node_prefix "" {
   policy = "write"
}
service_prefix "" {
  policy = "read"
}
EOF

cat > /tmp/consul-anonymous-policy <<EOF
node_prefix "" {
  policy = "read"
}
service_prefix "" {
  policy = "read"
}
agent_prefix "" {
  policy = "read"
}
EOF

cat > /tmp/consul-replication-policy <<EOF
acl = "write"
EOF

cat > /tmp/vault-access-token-policy <<EOF
key_prefix "${vault_kv_path}/" {
    policy = "write"
}
service "${vault_service_name}" {
    policy = "write"
}
node_prefix "" {
    policy = "write"
}
agent_prefix "" {
    policy = "write"
}
session_prefix "" {
    policy = "write"
}
EOF

if [[ $exit_code -eq 0 ]]; then
  echo "INFO: This is the leader node"
  echo "INFO: Creating the necessary policies"
  for i in consul-agent-policy consul-anonymous-policy consul-replication-policy vault-access-token-policy
  do
    echo "INFO: Creating the $i"
    consul acl policy create -name $i -description $i -rules @/tmp/$i
    exit_status=$?
    while [[ $exit_status -ne 0 ]];
    do
      sleep 2
      consul acl policy create -name $i -description $i -rules @/tmp/$i
      exit_status=$?
    done
  done
  echo "INFO: Creating the necessary tokens"
  echo "INFO: Creating the replication Token"
  consul acl token create -description "ACL Replication Token" -policy-name "consul-replication-policy"
  echo "INFO: Updating the Anonymous Token with the policy"
  consul acl token update -id "00000000-0000-0000-0000-000000000002" -policy-name "consul-anonymous-policy"
  echo "INFO: Creating Vault Access Token"
  consul acl token create -description "Vault Access Token" -policy-name "vault-access-token-policy"
  echo "INFO: Creating Consul Management Token"
  consul acl token create -description "Consul Management Token" -policy-name "global-management"
  if [[ $restore_from_backup = "yes" ]]; then
    latest_backup_file=$(aws s3 ls $restore_bucket | sort | tail -1 | awk '{print $4}')
    echo "INFO: Coping $latest_backup_file from $restore_bucket"
    aws s3 cp s3://$restore_bucket/$latest_backup_file /tmp/
    echo "INFO: Restore from Snapshot"
    consul snapshot restore /tmp/$latest_backup_file
    if [[ $? -eq 0 ]]; then
      rm /tmp/$latest_backup_file
    fi
  fi
fi

echo "INFO: Performing tasks which are required both for leader and follower"
for i in consul-agent-policy consul-anonymous-policy consul-replication-policy vault-access-token-policy
do
  rm /tmp/$i
done
echo "INFO: Wait till you get the consul-agent-policy created. Useful when this is first cluster getting created"
consul acl policy list | grep -i consul-agent-policy
exit_code=$?
while [[ $exit_code -ne 0 ]];
do
  consul acl policy list | grep -i consul-agent-policy
  exit_code=$?
done
echo "INFO: Creating a Agent Token"
consul acl token create -description $hostname -policy-name "consul-agent-policy" | tee /tmp/agent_token
agent_token=$(cat /tmp/agent_token | grep SecretID | awk '{print $2}')
consul acl set-agent-token agent $agent_token
rm /tmp/agent_token

echo "INFO: Getting the Replication Token"
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
        if [[ $part2 = "ACL Replication Token" ]]; then
          echo "INFO: Found the ACL Replication token"
          found="yes"
          break
        fi
      fi
  done < /tmp/all_tokens
  consul acl token list | tee /tmp/all_tokens
done
rm /tmp/all_tokens
echo "INFO: Setting the Replication Token"
consul acl token read -id $search_id | tee /tmp/replication_token
replication_token=$(cat /tmp/replication_token | grep SecretID | awk '{print $2}')
consul acl set-agent-token replication $replication_token
rm /tmp/replication_token

echo "INFO: Updating the consul config to preserve the tokens during reboot"
cat > ${config_path}/consul-tokens.json <<EOF
{
  "acl": {
    "tokens": {
        "agent": "$agent_token",
        "replication": "$replication_token"
    }
  }
}
EOF

chown ${user_name}:${group_name} /consul/config/consul-tokens.json
chmod 640 ${config_path}/consul-tokens.json
