#!/bin/bash
cat > /etc/systemd/system/consul-agent.service <<SERVICEEOF
[Unit]
Description=Consul Agent Client Mode
After=docker.service cloudwatchlogs-env-file-setup.service
Requires=docker.service cloudwatchlogs-env-file-setup.service

[Service]
EnvironmentFile=/consul/server_details
TimeoutStartSec=0
Restart=always
ExecStart=-/usr/local/bin/consul agent -config-dir=${consul_config_path}
ExecStop=-/usr/local/bin/consul leave
User=${consul_user_name}
Group=${consul_group_name}

[Install]
WantedBy=multi-user.target
SERVICEEOF

cat > /etc/systemd/system/vault-server.service <<SERVICEEOF
[Unit]
Description=Vault Server
After=docker.service consul-agent.service
Requires=docker.service consul-agent.service

[Service]
EnvironmentFile=/vault/server_details
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/sleep 60
ExecStart=-/usr/local/bin/vault server -config=${vault_config_path}/${vault_config_name}
User=${vault_user_name}
Group=${vault_group_name}

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable consul-agent.service
systemctl enable vault-server.service
systemctl start consul-agent
systemctl start vault-server
