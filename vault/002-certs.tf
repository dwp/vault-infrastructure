#-------------------------------------------------------------
### Setting the common name for the applications
#-------------------------------------------------------------
data "null_data_source" "blue-common-name" {
  count = "${var.total_no_of_vault_servers["blue"]}"
  inputs = {
    common_name = "${local.dns_server_entry_prefix["blue"]}-${count.index}.${var.dhcp_domain}"
  }
}

data "null_data_source" "green-common-name" {
  count = "${var.total_no_of_vault_servers["green"]}"
  inputs = {
    common_name = "${local.dns_server_entry_prefix["green"]}-${count.index}.${var.dhcp_domain}"
  }
}

data "null_data_source" "blue_ssm_names" {
  count = "${local.len_blue_servers}"
  inputs = {
    vault_server_ssm_names = "/certs/${var.project}/${var.environment}/blue-vault-server-${count.index}-key"
    consul_agent_ssm_names = "/certs/${var.project}/${var.environment}/blue-vault-consul-agent-${count.index}-key"
    consul_client_ssm_names = "/certs/${var.project}/${var.environment}/blue-vault-consul-client-${count.index}-key"
  }
}
data "null_data_source" "green_ssm_names" {
  count = "${local.len_green_servers}"
  inputs = {
    vault_server_ssm_names = "/certs/${var.project}/${var.environment}/green-vault-server-${count.index}-key"
    consul_agent_ssm_names = "/certs/${var.project}/${var.environment}/green-vault-consul-agent-${count.index}-key"
    consul_client_ssm_names = "/certs/${var.project}/${var.environment}/green-vault-consul-client-${count.index}-key"
  }
}

#--------------------------------------------------------------
### Create Vault Server Certificates
#--------------------------------------------------------------

module "blue_vault_server_cert_key" {
  source = "./tls/private_key"
  no_of_keys = "${var.total_no_of_vault_servers["blue"]}"
  algorithm = "${var.cert_algorithm["vault"]}"
  rsa_key_size = "${var.cert_key_length["vault"]}"
}

module "blue_vault_server_csr" {
  source = "./tls/csr"
  algorithm = "${var.cert_algorithm["vault"]}"
  no_of_keys = "${var.total_no_of_vault_servers["blue"]}"
  private_keys = "${module.blue_vault_server_cert_key.private_key_pem}"
  dns_names = ["${local.dns_cname["blue"]}","${local.dns_cname["common"]}"]
  common_name = ["${data.null_data_source.blue-common-name.*.outputs.common_name}"]
}

module "green_vault_server_cert_key" {
  source = "./tls/private_key"
  no_of_keys = "${var.total_no_of_vault_servers["green"]}"
  algorithm = "${var.cert_algorithm["vault"]}"
  rsa_key_size = "${var.cert_key_length["vault"]}"
}

module "green_vault_server_csr" {
  source = "./tls/csr"
  algorithm = "${var.cert_algorithm["vault"]}"
  no_of_keys = "${var.total_no_of_vault_servers["green"]}"
  private_keys = "${module.green_vault_server_cert_key.private_key_pem}"
  dns_names = ["${local.dns_cname["green"]}","${local.dns_cname["common"]}"]
  common_name = ["${data.null_data_source.green-common-name.*.outputs.common_name}"]
}

#Upload to SSM due to the User data size limit issue
module "upload_blue_vault_server_keys"  {
  source = "./ssm/parameter"
  ssm_name = "${data.null_data_source.blue_ssm_names.*.outputs.vault_server_ssm_names}"
  ssm_type = ["SecureString"]
  ssm_value = "${module.blue_vault_server_cert_key.private_key_pem}"
  ssm_description = ["blue-${var.project}-${var.environment}-certs-and-keys"]
  ssm_keyid = "${data.terraform_remote_state.basic-infra.kms_key_id[0]}"
  ssm_overwrite = "true"
  project = "${var.project}"
  environment = "${var.environment}"
}

module "upload_green_vault_server_keys"  {
  source = "./ssm/parameter"
  ssm_name = "${data.null_data_source.green_ssm_names.*.outputs.vault_server_ssm_names}"
  ssm_type = ["SecureString"]
  ssm_value = "${module.green_vault_server_cert_key.private_key_pem}"
  ssm_description = ["green-${var.project}-${var.environment}-certs-and-keys"]
  ssm_keyid = "${data.terraform_remote_state.basic-infra.kms_key_id[0]}"
  ssm_overwrite = "true"
  project = "${var.project}"
  environment = "${var.environment}"
}

#-------------------------------------------------------------
### Consul Client Certificate
#-------------------------------------------------------------
data "null_data_source" "blue-common-name-consul-client" {
  count = "${var.total_no_of_vault_servers["blue"]}"
  inputs = {
    common_name = "${local.dns_consul_client_entry_prefix["blue"]}-${count.index}.${var.dhcp_domain}"
  }
}

data "null_data_source" "green-common-name-consul-client" {
  count = "${var.total_no_of_vault_servers["green"]}"
  inputs = {
    common_name = "${local.dns_consul_client_entry_prefix["green"]}-${count.index}.${var.dhcp_domain}"
  }
}

module "blue_consul_client_cert_key" {
  source = "./tls/private_key"
  no_of_keys = "${var.total_no_of_vault_servers["blue"]}"
  algorithm = "${var.cert_algorithm["vault"]}"
  rsa_key_size = "${var.cert_key_length["vault"]}"
}

module "blue_consul_client_csr" {
  source = "./tls/csr"
  algorithm = "${var.cert_algorithm["vault"]}"
  no_of_keys = "${var.total_no_of_vault_servers["blue"]}"
  private_keys = "${module.blue_consul_client_cert_key.private_key_pem}"
  common_name = ["${data.null_data_source.blue-common-name.*.outputs.common_name}"]
}

module "green_consul_client_cert_key" {
  source = "./tls/private_key"
  no_of_keys = "${var.total_no_of_vault_servers["green"]}"
  algorithm = "${var.cert_algorithm["vault"]}"
  rsa_key_size = "${var.cert_key_length["vault"]}"
}

module "green_consul_client_csr" {
  source = "./tls/csr"
  algorithm = "${var.cert_algorithm["vault"]}"
  no_of_keys = "${var.total_no_of_vault_servers["green"]}"
  private_keys = "${module.green_consul_client_cert_key.private_key_pem}"
  common_name = ["${data.null_data_source.green-common-name.*.outputs.common_name}"]
}

#Upload to SSM due to the User data size limit issue
module "upload_blue_consul_client_keys"  {
  source = "./ssm/parameter"
  ssm_name = "${data.null_data_source.blue_ssm_names.*.outputs.consul_client_ssm_names}"
  ssm_type = ["SecureString"]
  ssm_value = "${module.blue_consul_client_cert_key.private_key_pem}"
  ssm_description = ["blue-${var.project}-${var.environment}-certs-and-keys"]
  ssm_keyid = "${data.terraform_remote_state.basic-infra.kms_key_id[0]}"
  ssm_overwrite = "true"
  project = "${var.project}"
  environment = "${var.environment}"
}

module "upload_green_consul_client_keys"  {
  source = "./ssm/parameter"
  ssm_name = "${data.null_data_source.green_ssm_names.*.outputs.consul_client_ssm_names}"
  ssm_type = ["SecureString"]
  ssm_value = "${module.green_consul_client_cert_key.private_key_pem}"
  ssm_description = ["green-${var.project}-${var.environment}-certs-and-keys"]
  ssm_keyid = "${data.terraform_remote_state.basic-infra.kms_key_id[0]}"
  ssm_overwrite = "true"
  project = "${var.project}"
  environment = "${var.environment}"
}

#-------------------------------------------------------------
### Consul Agent(Client Mode) Certificate
#-------------------------------------------------------------
module "blue_consul_agent_cert_key" {
  source = "./tls/private_key"
  no_of_keys = "${var.total_no_of_vault_servers["blue"]}"
  algorithm = "${var.cert_algorithm["vault"]}"
  rsa_key_size = "${var.cert_key_length["vault"]}"
}

module "blue_consul_agent_csr" {
  source = "./tls/csr"
  algorithm = "${var.cert_algorithm["vault"]}"
  no_of_keys = "${var.total_no_of_vault_servers["blue"]}"
  private_keys = "${module.blue_consul_agent_cert_key.private_key_pem}"
  common_name = ["${data.null_data_source.blue-common-name.*.outputs.common_name}"]
}

module "green_consul_agent_cert_key" {
  source = "./tls/private_key"
  no_of_keys = "${var.total_no_of_vault_servers["green"]}"
  algorithm = "${var.cert_algorithm["vault"]}"
  rsa_key_size = "${var.cert_key_length["vault"]}"
}

module "green_consul_agent_csr" {
  source = "./tls/csr"
  algorithm = "${var.cert_algorithm["vault"]}"
  no_of_keys = "${var.total_no_of_vault_servers["green"]}"
  private_keys = "${module.green_consul_agent_cert_key.private_key_pem}"
  common_name = ["${data.null_data_source.green-common-name.*.outputs.common_name}"]
}

#Upload to SSM due to the User data size limit issue
module "upload_blue_consul_agent_keys"  {
  source = "./ssm/parameter"
  ssm_name = "${data.null_data_source.blue_ssm_names.*.outputs.consul_agent_ssm_names}"
  ssm_type = ["SecureString"]
  ssm_value = "${module.blue_consul_agent_cert_key.private_key_pem}"
  ssm_description = ["blue-${var.project}-${var.environment}-certs-and-keys"]
  ssm_keyid = "${data.terraform_remote_state.basic-infra.kms_key_id[0]}"
  ssm_overwrite = "true"
  project = "${var.project}"
  environment = "${var.environment}"
}

module "upload_green_consul_agent_keys"  {
  source = "./ssm/parameter"
  ssm_name = "${data.null_data_source.green_ssm_names.*.outputs.consul_agent_ssm_names}"
  ssm_type = ["SecureString"]
  ssm_value = "${module.green_consul_agent_cert_key.private_key_pem}"
  ssm_description = ["green-${var.project}-${var.environment}-certs-and-keys"]
  ssm_keyid = "${data.terraform_remote_state.basic-infra.kms_key_id[0]}"
  ssm_overwrite = "true"
  project = "${var.project}"
  environment = "${var.environment}"
}
