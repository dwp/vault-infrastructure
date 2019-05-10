#!/usr/bin/python
import boto3, logging, os, json, base64
ssm_client = boto3.client('ssm',region_name='${region}')
logger = logging.getLogger()
logger.setLevel(logging.INFO)
# Download the required gpg keys
vault_unseal_key_path_prefix = "/vault-unseal-key-holders/"
vault_data_path = "${vault_data_path}"
response = ssm_client.describe_parameters(
    ParameterFilters = [
        {
            'Key': 'Name',
            'Option': 'BeginsWith',
            'Values': [
                vault_unseal_key_path_prefix
            ]
        }
    ]
)
Parameters = response['Parameters']
NextToken = response['NextToken']
while NextToken != "" :
    response1 = ssm_client.describe_parameters(
        ParameterFilters = [
            {
                'Key': 'Name',
                'Option': 'BeginsWith',
                'Values': [
                    vault_unseal_key_path_prefix
                ]
            }
        ],
        NextToken = NextToken
    )
    try:
        NextToken = response1['NextToken']
    except:
        NextToken = ""
    Parameters = Parameters + response1['Parameters']
count = 0
ssm_path = []
while count < len(Parameters):
    ssm_path.append(Parameters[count]['Name'])
    count += 1
response = ssm_client.get_parameters(
    Names = ssm_path
)
count=0
email_ids=""
encoded_gpgkey=""
while count < len(response['Parameters']):
    name = response['Parameters'][count]['Name'].split("/")[2]
    email = response['Parameters'][count]['Value'].split(",")[0]
    gpg_key = response['Parameters'][count]['Value'].split(",")[1]
    encoded_gpgkey = base64.b64encode(gpg_key)
    file = open(vault_data_path + "/" + name + ".gpg","w")
    file.write(gpg_key)
    file.close()
    if count == 0:
        email_ids = email
        name_order = name
    else:
        email_ids = email_ids + " " + email
        name_order = name_order + " " + name
    count += 1
#Create a base64 encoded json gpg_file
file = open(vault_data_path + "/email_ids","w")
file.write(email_ids)
file.close()
file = open(vault_data_path + "/name_order","w")
file.write(name_order)
file.close()

#Download all the initial policies for Vault
policies = ${policy_names}
for i in policies:
    response = ssm_client.get_parameters(
        Names = [
            "/vault-init-config/${project}/${environment}/${deployment_mode}-" + i
        ],
        WithDecryption = True
    )
    value = response['Parameters'][0]['Value']
    file = open(vault_data_path + "/" + i + ".hcl","w")
    file.write(value)
    file.close()

for i in ["vault-server","vault-consul-agent","vault-consul-client"]:
    if i == "vault-server":
        ssl_path = "${vault_ssl_path}"
        cert_name = "${vault_server_cert_name}"
        key_name = "${vault_server_key_name}"
    if i == "vault-consul-agent":
        ssl_path = "${consul_ssl_path}"
        cert_name = "${consul_agent_cert_name}"
        key_name = "${consul_agent_key_name}"
    if i == "vault-consul-client":
        ssl_path = "${vault_ssl_path}"
        cert_name = "${consul_client_cert_name}"
        key_name = "${consul_client_key_name}"

    response = ssm_client.get_parameters(
        Names = [
            "/certs/${project}/${environment}/${deployment_mode}-" + i + "-${seq_number}-cert"
        ],
        WithDecryption = True
    )
    file = open(ssl_path + "/" + cert_name,"w")
    file.write(response['Parameters'][0]['Value'])
    file.close()

    response = ssm_client.get_parameters(
        Names = [
            "/certs/${project}/${environment}/${deployment_mode}-" + i + "-${seq_number}-key"
        ],
        WithDecryption = True
    )
    file = open(ssl_path + "/" + key_name,"w")
    file.write(response['Parameters'][0]['Value'])
    file.close()
