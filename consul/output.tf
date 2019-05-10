# From 002-certs.tf
output "blue_consul_server_csr" {
  value = "${module.blue_consul_server_csr.csr_pem}"
  description = "List of CSR of Blue Mode Consul Server Agents"
}

output "green_consul_server_csr" {
  value = "${module.green_consul_server_csr.csr_pem}"
  description = "List of CSR of Green Mode Consul Server Agents"
}


output "blue_consul_client_csr" {
  value = "${module.blue_consul_client_csr.csr_pem}"
  description = "List of CSR of Blue Mode Consul Client Agents"
}

output "green_consul_client_csr" {
  value = "${module.green_consul_client_csr.csr_pem}"
  description = "List of CSR of Green Mode Consul Client Agents"
}

# From 003-user-data.tf
output "uuids" {
  value = "${random_uuid.uuids.*.result}"
  description = "List of UUIDs created for Consul Server"
}

output "backup_bucket_name" {
  value = "${module.backup_bucket.bucket_id}"
  description = "Consul Backup Bucket name"
}

output "backup_bucket_arn" {
  value = "${module.backup_bucket.bucket_arn}"
  description = "Consul Backup Bucket ARN"
}

# From 004-consul.tf
output "blue_running_instance_ids" {
  value = "${module.blue-consul-servers.instance_id}"
  description = "Consul Blue Instance IDs"
}

output "green_running_instance_ids" {
  value = "${module.green-consul-servers.instance_id}"
  description = "Consul Green Instance IDs"
}

output "consul_sg_id" {
  value = "${module.consul_sg.sg_id}"
  description = "Consul  SG IDs"
}

output "blue_common_dns_fqdn" {
  value = "${module.blue-server-common-A-record.record_fqdn}"
  description = "Consul Server Blue FQDN"
}

output "green_common_dns_fqdn" {
  value = "${module.green-server-common-A-record.record_fqdn}"
  description = "Consul Server Green FQDN"
}

output "server_dns_fqdn" {
  value = "${coalescelist(module.attach-server-blue-cname.record_fqdn,module.attach-server-green-cname.record_fqdn)}"
  description = "Consul Server FQDN"
}

#To be exported for all other places
output "dc_name" {
  value = "${local.dc_name}"
  description = "Consul Data centre name"
}

output "all_consul_ports" {
  value = "${split(" ",local.consul_ports)}"
  description = "Consul Ports"
}

output "consul_app_ports" {
  value = "${split(" ",var.consul_ports)}"
  description = "Consul Non HTTP/HTTPs Ports"
}

output "consul_https_port" {
  value = "${var.consul_https_port}"
  description = "Consul HTTPs Port"
}

output "vault_token_ssm_path" {
  value = "${var.vault_token_ssm_path}"
  description = "Vault Access Token SSM Path"
}
