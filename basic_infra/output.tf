output "ssh_key_name" {
  value = "${module.vault-basic-infra.ssh_key_name}"
  description = "List of SSH Key name"
}

output "generic_sg_id" {
  value = "${module.vault-basic-infra.generic_sg_id}"
  description = "List of Generic SG ID created"
}

output "subnet_ids" {
  value = "${module.vault-basic-infra.subnet_ids}"
  description = "List of Lists of Subnet IDs created for subnet_names"
}

output "vpc_id" {
  value = "${module.vault-basic-infra.vpc_id}"
  description = "VPC ID of the Infrastructure"
}

output "vpc_cidr" {
  value = "${module.vault-basic-infra.vpc_cidr}"
  description = "VPC CIDR of the infrastructure"
}

output "dns_server" {
  value = "${module.vault-basic-infra.dns_server}"
  description = "DNS Server of the VPC DHCP options"
}

output "zone_id" {
  value = "${module.vault-basic-infra.associated_private_zone_id}"
  description = "Zone ID of the associated Route53 Zone"
}

output "kms_key_id" {
  value = "${module.kms_key.kms_key_id}"
  description = "KMS Key ID for Consul Encryption"
}

output "kms_key_arn" {
  value = "${module.kms_key.kms_arn}"
}
