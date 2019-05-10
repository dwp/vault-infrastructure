#From 002-certs.tf
output "blue_vault_server_csr" {
  value = "${module.blue_vault_server_csr.csr_pem}"
  description = "List of CSR of Blue Mode Vault Server Nodes"
}

output "green_vault_server_csr" {
  value = "${module.green_vault_server_csr.csr_pem}"
  description = "List of CSR of Green Mode Vault Server Nodes"
}

output "blue_consul_client_csr" {
  value = "${module.blue_consul_client_csr.csr_pem}"
  description = "List of CSR of Blue Mode Vault Client to Consul Agent"
}

output "green_consul_client_csr" {
  value = "${module.green_consul_client_csr.csr_pem}"
  description = "List of CSR of Green Mode Vault Client to Consul Agent"
}

output "blue_consul_agent_csr" {
  value = "${module.blue_consul_agent_csr.csr_pem}"
  description = "List of CSR of Blue Mode Consul Agent on Vault Node"
}

output "green_consul_agent_csr" {
  value = "${module.green_consul_agent_csr.csr_pem}"
  description = "List of CSR of Green Mode Consul Agent on Vault Node"
}

# From 004-vault.tf
output "blue_running_instance_ids" {
  value = "${module.blue-vault-servers.instance_id}"
  description = "Vault Blue Instance IDs"
}

output "green_running_instance_ids" {
  value = "${module.green-vault-servers.instance_id}"
  description = "Vault Green Instance IDs"
}

output "vault_sg_id" {
  value = "${module.vault_sg.sg_id}"
  description = "Vault  SG IDs"
}

output "blue_common_dns_fqdn" {
  value = "${module.blue-server-common-A-record.record_fqdn}"
  description = "Vault Server Blue FQDN"
}

output "green_common_dns_fqdn" {
  value = "${module.green-server-common-A-record.record_fqdn}"
  description = "Vault Server Green FQDN"
}

output "server_dns_fqdn" {
  value = "${coalescelist(module.attach-server-blue-cname.record_fqdn,module.attach-server-green-cname.record_fqdn)}"
  description = "Vault Server FQDN"
}

#To be exported for all other places
output "all_vault_ports" {
  value = "${split(" ",local.vault_ports)}"
  description = "Vault Ports"
}

output "vault_app_ports" {
  value = "${split(" ",var.vault_port)}"
  description = "Vault Server Port"
}

output "vault_cluster_port" {
  value = "${var.vault_cluster_port}"
  description = "Vault Server Port"
}

output "vault_token_ssm_path" {
  value = "${var.vault_token_ssm_path}"
  description = "Vault Access Token SSM Path"
}
