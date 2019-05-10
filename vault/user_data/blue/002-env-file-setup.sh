#!/bin/sh

# Set this variables For Consul Agent

cat > /consul/server_details <<EOF
CONSUL_HTTP_ADDR="${node_name}-${seq_number}.${domain_name}:${consul_https_port}"
CONSUL_HTTP_SSL="true"
CONSUL_HTTP_SSL_VERIFY="true"
CONSUL_CAPATH="${ca_path}"
CONSUL_CLIENT_CERT="${vault_ssl_path}/${consul_client_cert_name}"
CONSUL_CLIENT_KEY="${vault_ssl_path}/${consul_client_key_name}"
EOF
chmod 755 /consul/server_details

# Set this variables For Vault Client
cat > /vault/server_details <<EOF
VAULT_ADDR="https://${node_name}-${seq_number}.${domain_name}:${vault_port}"
VAULT_CACERT=${ca_file}
EOF
chmod 755 /vault/server_details
