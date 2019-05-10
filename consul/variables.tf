# Common Variables
variable "region" {
  description = "Region whether Consul Servers are created"
}
variable "project" {
  description = "Project for which the Consul Servers are created"
}
variable "environment" {
  description = "Environment for which the Consul Servers are created"
}
variable "is_blue_mode_active" {
  description = "Accepts yes or no. Indicates to keep, create or destroy blue mode servers "
}
variable "is_green_mode_active" {
  description = "Accepts yes or no. Indicates to keep, create or destroy green mode servers "
}
variable "keep_dns_deployment_mode" {
  description = "Accepts blue or green. This is to either keep existing dns or switch over to a different mode"
}
variable "dhcp_domain" {
  description = "Route53 Domain Zone"
}
variable "ami_disk_presents" {
  type = "map"
  description = "Number of disk presented by default in AMI for blue and green servers"
}
variable "no_of_uuids_to_generate" {
  description = "Number of UUIDs to generate for initial Consul Setup"
}
variable "slack_project_code" {
  type = "list"
  description = "Slack Project code to send alerts to"
}
variable "slack_topic_terraform_state" {
  description = "Slack Terraform remote state path to get slack information"
}
variable "common_vpc_terraform_state" {
  description = "VPN VPC Terraform remote state path"
}
variable "common_project" {
  description = "Monitoring Project Name"
}
variable "common_environment" {
  description = "Monitoring Environment Name"
}
variable "team" {
  description = "Short name of the project to be used in slack,consul,etc"
}
variable "vault_token_ssm_path" {
  description = "SSM Path where Vault initial Consul Token will be copied"
}
variable "vault_backend_token_name" {
  description = "name of the Vault Initial Consul Token"
}
variable "consul_ports" {
  description = "Consul non https ports"
}
variable "consul_https_port" {
  description = "Consul HTTPS Port"
}
variable "consul_domain_name" {
  description = "Consul Domain Name"
}
variable "grpc_port" {
  description = "Consul GRPC Port"
}

# 001-data_modules.tf variables
variable "basic_infra_terraform_state" {
  description = "Terraform Remote State of basic_infra folder"
}
variable "hardened_ami_name" {
  description = "Hardened AMI Name to Search"
}
variable "hardened_ami_architecture" {
  description = "Hardened AMI architecture to search"
}
variable "hardened_ami_virt_type" {
  description = "Hardened AMI Virtual Type to search"
}
variable "dev_availability_zone" {
  description = "Dev Availability Zone values"
}

# 002-certs.tf variables . Some may be used in other tf files
variable "instance_short_name" {
  type = "map"
  description = "Instance Short names to use for both blue and green"
}
variable "total_no_of_consul_servers" {
  type = "map"
  description = "Number of Consul servers to create for both blue and green"
}
variable "consul_dc_name_prefix" {
  description = "Consul Data centre name prefix"
}
variable "cert_algorithm" {
  type = "map"
  description = "Private Key Algorithm to create for both blue and green"
}
variable "cert_key_length" {
  type = "map"
  description = "Private Key Length to create for both blue and green"
}


# 003-user-data.tf variables. Some may be used in other tf files
variable "blue_consul_config_parameters" {
  type = "map"
  description = "Consul Server Agent Configuration Values for Blue Mode"
}
variable "green_consul_config_parameters" {
  type = "map"
  description = "Consul Server Agent Configuration for Green Mode"
}
variable "blue_consul_user_data_scripts" {
  type = "list"
  description = "Local User Data scripts path for Blue Mode"
}
variable "green_consul_user_data_scripts" {
  type = "list"
  description = "Local User Data scripts path for Green Mode"
}
variable "blue_consul_user_data_config" {
  type = "map"
  description = "User Data script values for Blue Mode"
}
variable "green_consul_user_data_config" {
  type = "map"
  description = "User Data script values for Green Mode"
}
variable "user_name" {
  type = "map"
  description = "Ownership user name for Consul Agent in blue and green mode"
}
variable "group_name" {
  type = "map"
  description = "Ownership group name for Consul Agent in blue and green mode"
}
variable "user_id" {
  type = "map"
  description = "Ownership user id for Consul Agent in blue and green mode"
}
variable "group_id" {
  type = "map"
  description = "Ownership group id for Consul Agent in blue and green mode"
}
variable "consul_token_parameters" {
  type = "map"
  description = "Consul ACL Token Parameters for Blue and Green Mode"
}

#004-consul.tf variables. Some may be used in other tf files
variable "consul_instance_policy" {
  type = "map"
  description = "Instance Policy to add to Standard IAM policy for both blue and green mode"
}
variable "sg_name" {
  type = "map"
  description = "Security Group for blue and green mode"
}
variable "consul_ebs_volume_size" {
  type = "map"
  description = "Consul EBS volume Sizes for blue and green mode"
}
variable "consul_ebs_volume_type" {
  type = "map"
  description = "Consul EBS volume Type for blue and green mode"
}
variable "consul_ebs_encrypted" {
  type = "map"
  description = "Consul EBS encryption boolean status for blue and green mode"
}
variable "consul_instance_prefix" {
  type = "map"
  description = "Consul Instance Type Prefix (Example: m5) for blue and green mode"
}
variable "consul_instance_type" {
  type = "map"
  description = "Consul Instance Type for blue and green mode"
}
variable "subnet_to_build_for_consul" {
  type = "map"
  description = "Consul subnet names to build for blue and green mode"
}
variable "ec2_role_names" {
  type = "map"
  description = "Consul EC2 IAM Role names to build for Consul Servers"
}
variable "consul_number_of_ebs_devices" {
  type = "map"
  description = "Number of ebs devices to attach for green and blue"
}
variable "subnet_names" {
  type = "list"
  description = "All Subnet names available in the VPC"
}
variable "blue_consul_vg_config" {
  type = "map"
  description = "VG Configuration for Blue Mode consul server"
}
variable "green_consul_vg_config" {
  type = "map"
  description = "VG Configuration for Green Mode consul server"
}
variable "blue_vault_config_parameters" {
  type = "map"
  description = "Consul Client Configuration for Blue Mode consul server"
}
variable "green_vault_config_parameters" {
  type = "map"
  description = "Consul Client Configuration for Blue Mode consul server"
}
