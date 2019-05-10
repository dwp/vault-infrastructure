#!/bin/bash
cat > /etc/systemd/system/consul-server.service <<SERVICEEOF
[Unit]
Description=Consul Server Startup
After=docker.service cloudwatchlogs-env-file-setup.service
Requires=docker.service cloudwatchlogs-env-file-setup.service

[Service]
EnvironmentFile=/consul/server_details
TimeoutStartSec=0
Restart=always
ExecStart=-/usr/local/bin/consul agent -config-dir=${config_path}
ExecStop=-/usr/local/bin/consul leave
User=${user_name}
Group=${group_name}

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable consul-server.service
systemctl start consul-server
