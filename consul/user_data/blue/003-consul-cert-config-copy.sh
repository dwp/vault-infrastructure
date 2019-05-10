#!/bin/bash

cat > ${config_path}/${consul_config_name} <<EOF
${consul_config}
EOF

cat > ${ssl_path}/${consul_server_cert_name} <<EOF
${consul_server_cert}
EOF

cat > ${ssl_path}/${consul_server_key_name} <<EOF
${consul_server_key}
EOF

cat > ${ssl_path}/${consul_client_cert_name} <<EOF
${consul_client_cert}
EOF

cat > ${ssl_path}/${consul_client_key_name} <<EOF
${consul_client_key}
EOF

node_ip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
sed -i -e "s/{consul_node_ip}/$node_ip/g" ${config_path}/${consul_config_name}

mount_points="${mount_points}"
decoded_mount_points=`echo $mount_points | tr -d '[' | tr -d ']' | tr ',' ' '`
for i in $decoded_mount_points
do
  chown -R ${user_name}:${group_name} $i
done

chmod 640 ${config_path}/${consul_config_name}
