#!/bin/sh

# Set this variables and in /consul/server_details also

cat > /consul/server_details <<EOF
CONSUL_HTTP_ADDR="${host_name}:${https_port}"
CONSUL_HTTP_SSL="true"
CONSUL_HTTP_SSL_VERIFY="true"
CONSUL_CAPATH="${ca_path}"
CONSUL_CLIENT_CERT="${ssl_path}/${consul_client_cert_name}"
CONSUL_CLIENT_KEY="${ssl_path}/${consul_client_key_name}"
CONSUL_TLS_SERVER_NAME="${consul_server_name}"
CONSUL_LICENSE="${consul_license}"
BACKUP_BUCKET="${backup_bucket}"
EOF

chmod 755 /consul/server_details
