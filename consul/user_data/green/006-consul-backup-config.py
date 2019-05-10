#!/usr/bin/python
'''
This will configure the Backup script and runs as per the configuration and it will only run from the leader node
This script is not required when running Enterprise and needs changing
Since the first set up is OpenSource , this will be run as is
'''
import os,json
systemd_srv_file = """[Unit]
Description=Consul Data Backup
After=consul-server.service
Requires=consul-server.service

[Service]
Type=oneshot
EnvironmentFile=/consul/server_details
TimeoutStartSec=0
ExecStart=-/bin/python /consul/backup_consul.py
User=${user_name}
Group=${group_name}

[Install]
WantedBy=multi-user.target
"""

systemd_timer_file = """[Unit]
Description=Run consul-data-backup.service every ${BACKUP_FREQUENCY} minutes
After=consul-server.service
Requires=consul-server.service

[Timer]
OnBootSec=0min
OnUnitActiveSec=${BACKUP_FREQUENCY}min

[Install]
WantedBy=multi-user.target
"""

backup_script="""#!/usr/bin/python
import boto3,os,json,datetime,time
acl_token_file = json.loads(open("${config_path}/${consul_config_name}").read())
TOKEN = acl_token_file['acl']['tokens']['master']
os.environ['CONSUL_HTTP_TOKEN'] = TOKEN
print ("INFO: Checking if this node is the leader")
hostname = os.popen("hostname").read().rstrip('\\n')
consul_output = os.popen("consul operator raft list-peers | grep -i leader").read()
if hostname in consul_output[:]:
    print ("INFO: This is the leader node. Taking the backup")
    time_now = datetime.datetime.now().strftime("%d-%m-%Y-%H-%M-%S")
    os.system("consul snapshot save ${backup_path}/consul-backup-on-" + str(time_now))
    count = 60
    while not os.path.exists('${backup_path}/consul-backup-on-' + str(time_now)):
        print ("INFO: Backup Not completed yet. Will check after 5 secs. I will check for another ",str(count)," times")
        time.sleep(5)
        count -= 1
        if count == 0:
            break

    if count != 0:
        print ("INFO: Backup completed. Copying to S3 bucket")
        os.system("aws s3 cp ${backup_path}/consul-backup-on-" + str(time_now) +" s3://${backup_bucket}/")
        print ("INFO: Removing the backup from the Server")
        os.system("rm ${backup_path}/consul-backup-on-" + str(time_now))
    else:
        print ("ERROR: Backup did not complete even after 300 secs. Sending an alert")
        sns_client = boto3.client('sns',region_name='${region}')
        payload = {}
        payload['attachments'] = [
            {
                "pretext": "Backup Failed for ${dc_name} Consul Server",
                "color": "danger",
                "text": "Backup did not complete even after 300 secs(5 mins)"
            }
        ]
        payload['printname'] = "consul-backup-check"
        payload['project'] = "${vault_slack_identifier}"
        response = sns_client.publish(
            TopicArn = "${slack_sns_topic_arn}",
            Message = json.dumps(payload)
        )
        print (response)
else:
    print ("INFO: This is not the leader node .Backup will not be taken here")
"""

with open("/consul/backup_consul.py","w") as backup_script_file:
    backup_script_file.write(backup_script)

with open("/etc/systemd/system/consul-data-backup.service","w") as systemdFile:
    systemdFile.write(systemd_srv_file)

with open("/etc/systemd/system/consul-data-backup.timer","w") as TimerFile:
    TimerFile.write(systemd_timer_file)

os.system("chown ${user_name}:${group_name} /consul/backup_consul.py")
os.system("systemctl daemon-reload")
os.system("systemctl enable consul-data-backup.service")
os.system("systemctl enable consul-data-backup.timer")
os.system("systemctl start consul-data-backup.timer")
