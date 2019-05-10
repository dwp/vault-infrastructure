#Common Variables
variable "region" {
  description = "Region whether Consul Servers are created"
}
variable "project" {
  description = "Project for which the Consul Servers are created"
}
variable "environment" {
  description = "Environment for which the Consul Servers are created"
}
variable "instance_short_name" {
  type = "map"
  description = "Instance Short names to use for both blue and green"
}
variable "dhcp_domain" {
  description = "Route53 Domain Zone"
}
variable "vault_backend_token_name" {
  description = "name of the Vault Initial Consul Token"
}
variable "vault_token_ssm_path" {
  description = "SSM Path where Vault initial Consul Token will be copied"
}
variable "consul_token_parameters" {
  type = "map"
  description = "Consul ACL Token Parameters for Blue and Green Mode"
}
variable "vault_port" {
  description = "Vault APP Port"
}
variable "vault_cluster_port" {
  description = "Vault Cluster Port"
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
variable "team" {
  description = "Short name of the project to be used in slack,vault,consul,etc"
}
variable "ami_disk_presents" {
  type = "map"
  description = "Number of disk presented by default in AMI for blue and green servers"
}
variable "consul_ports" {
  description = "Consul non https ports"
}
variable "consul_https_port" {
  description = "Consul HTTPS Port"
}
variable "user_name" {
  type = "map"
  description = "Ownership user name for Vault and Consul Agent in blue and green mode"
}
variable "group_name" {
  type = "map"
  description = "Ownership group name for Vault and Consul Agent in blue and green mode"
}
variable "user_id" {
  type = "map"
  description = "Ownership user id for Vault and Consul Agent in blue and green mode"
}
variable "group_id" {
  type = "map"
  description = "Ownership group id for Vault and Consul Agent in blue and green mode"
}
variable "common_project" {
  description = "Monitoring Project Name"
}
variable "common_environment" {
  description = "Monitoring Environment Name"
}
variable "grpc_port" {
  description = "Consul GRPC Port"
}

#001-data-modules.tf variables. Some may be used in other tf files
variable "basic_infra_terraform_state" {
  description = "Terraform Remote State of basic_infra folder"
}
variable "consul_terraform_state" {
  description = "Terraform Remote state of consul folder"
}
variable "common_vpc_terraform_state" {
  description = "VPN VPC Terraform remote state path"
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

#002-certs.tf variables. Some may be used in other tf files
variable "cert_algorithm" {
  type = "map"
  description = "Private Key Algorithm to create for both blue and green"
}
variable "cert_key_length" {
  type = "map"
  description = "Private Key Length to create for both blue and green"
}

#003-userdata.tf variables. Some may be used in other tf files
variable "consul_domain_name" {
  description = "Consul Domain Name"
}
variable "blue_vault_config_parameters" {
  type = "map"
  description = "Vault Server Configuration Values for Blue Mode"
}
variable "green_vault_config_parameters" {
  type = "map"
  description = "Vault Server Configuration Values for Green Mode"
}
variable "blue_vault_consul_agent_config_parameters" {
  type = "map"
  description = "Vault Server Consul Agent Configuration Values for Blue Mode"
}
variable "green_vault_consul_agent_config_parameters" {
  type = "map"
    description = "Vault Server Consul Agent Configuration Values for Green Mode"
}
variable "blue_vault_user_data_scripts" {
  type = "list"
  description = "Local User Data scripts path for Blue Mode for Vault Server"
}
variable "green_vault_user_data_scripts" {
  type = "list"
  description = "Local User Data scripts path for Green Mode for Vault Server"
}
variable "blue_consul_user_data_scripts" {
  type = "list"
  description = "Local User Data scripts path for Blue Mode for Consul Agent"
}
variable "green_consul_user_data_scripts" {
  type = "list"
  description = "Local User Data scripts path for Green Mode for Consul Agent"
}
variable "blue_vault_user_data_config" {
  type = "map"
  description = "User Data script values for Blue Mode for Vault Server"

}
variable "green_vault_user_data_config" {
  type = "map"
  description = "User Data script values for Green Mode for Vault Server"
}
variable "blue_vault_policies" {
  type = "list"
  description = "Vault ACL Policies for Blue mode"
}
variable "green_vault_policies" {
  type = "list"
  description = "Vault ACL Policies for Green mode"
}
variable "blue_vault_policy_dir" {
  description = "Vault ACL Policies local path for Blue mode"
}
variable "green_vault_policy_dir" {
  description = "Vault ACL Policies local path for Green mode"
}

variable "total_no_of_vault_servers" {
  type  = "map"
  description = "Number of Vault servers to create in both blue and green mode"
}
variable "blue_vault_vg_config" {
  type = "map"
  description = "VG configuration for Vault Server in blue mode"
}
variable "green_vault_vg_config" {
  type = "map"
  description = "VG configuration for Vault Server in green mode"
}
variable "blue_token_role_maps" {
  type = "list"
  description = "Token roles and policies to map in Vault blue mode. It is in the format token_role_name:vault_acl_policy"
}
variable "green_token_role_maps" {
  type = "list"
  description = "Token roles and policies to map in Vault green mode. It is in the format token_role_name:vault_acl_policy"
}
variable "blue_default_ldap_group_maps" {
  type = "list"
  description = "LDAP groups and policies to map in Vault blue mode. It is in the format ldap_group_name:vault_acl_policy"
}
variable "green_default_ldap_group_maps" {
  type = "list"
  description = "LDAP groups and policies to map in Vault green mode. It is in the format ldap_group_name:vault_acl_policy"
}
variable "green_new_project_policies" {
  description = "Vault ACL Policies for update operations in green mode"
}
variable "green_delete_project_policies" {
  description = "Vault ACL Policies for delete operations in green mode"
}
variable "blue_new_project_policies" {
  description = "Vault ACL Policies for update operations in blue mode"
}
variable "blue_delete_project_policies" {
  description = "Vault ACL Policies for delete operations in blue mode"
}

#004-vault.tf variables . Some may be used in other tf files
variable "vault_instance_policy" {
  type = "map"
  description = "IAM policy to add to Standard policies for both blue and green"
}
variable "sg_name" {
  type = "map"
  description = "Vault SG name for both blue and green"
}
variable "vault_ebs_volume_size" {
  type = "map"
    description = "Vault EBS volume Sizes for blue and green mode"
}
variable "vault_ebs_volume_type" {
  type = "map"
  description = "Vault EBS volume types for blue and green mode"
}
variable "vault_ebs_encrypted" {
  type = "map"
  description = "Vault EBS encryption boolean for blue and green mode"
}
variable "vault_instance_prefix" {
  type = "map"
  description = "Vault Instance Type Prefix (Example: m5) for blue and green mode"
}
variable "vault_instance_type" {
  type = "map"
  description = "Vault Instance Type for blue and green mode"
}
variable "subnet_to_build_for_vault" {
  type = "map"
  description = "Vault subnet names to build for blue and green mode"
}
variable "ec2_role_names" {
  type = "map"
  description = "vault EC2 IAM Role names to build for vault Servers"
}
variable "vault_number_of_ebs_devices" {
  type = "map"
  description = "Number of ebs devices to attach for green and blue"
}
variable "subnet_names" {
  type = "list"
  description = "All Subnet names available in the VPC"
}
variable "green_vault_disallowed_policies_in_token_role" {
  description = "Policy names to put in disallowed parameter in token role for Green Mode"
}
variable "blue_vault_disallowed_policies_in_token_role" {
  description = "Policy names to put in disallowed parameter in token role for blue Mode"
}
variable "vault_kms_grant_operations" {
  type = "map"
  description = "Operations to Grant for KMS Unseal Key for both blue and green"
}
