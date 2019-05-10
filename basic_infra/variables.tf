variable "environment" {
  description = "Environment for which the resources are created. Used for all environments, except Dev. Example : stage"
}
variable "project" {
  description = "Project for which the resources are created. Used for all environments, except Dev. Example: proj"
}
variable "common_dev_project" {
  description = "Existing Development VPC Project Name as resources are created in a existing VPC rather than a new VPC. Example: proj-common"
}
variable "common_dev_environment" {
  description = "Existing Development environment Name as resources are created in a existing VPC. Example: dev"
}
variable "existing_ssh_terraform_path" {
  description = "This is applicable only for Dev ,where resources are created in a existing VPC. This is the Terraform remote state path to fetch the SSH Key name. Example : ssh_keys/terraform.tfstate"
}
variable "common_project" {
  description = "VPN VPC Project Name. Example : proj-management"
}
variable "common_environment" {
  description = "VPN VPC Environment Name. Example: nonprod"
}
variable "region" {
  description = "Region where the resources are created. Example : eu-west-2"
}
variable "cidr_block" {
  description = "VPC CIDR Block to create. Example: 192.168.0.0/16"
}
variable "dhcp_domain" {
  description = "DHCP Domain to add to VPC DHCP Options. Example: example.local"
}
variable "subnet_names" {
  type = "list"
  description = "Names of the Subnets to create by the module. Example: list("public","private-1","private-2")"
}
variable "subnet_cidr_block" {
  type = "map"
  description = "CIDR Blocks to be used on each AZ for the subnet_names given. Example with 3 AZs: merge(map("public",list("192.168.0.0/24","192.168.1.0/24","192.168.2.0/24")) , map("private-1",list("192.168.3.0/24","192.168.4.0/24","192.168.5.0/24")), map("private-2",list("192.168.6.0/24","192.168.7.0/24","192.168.8.0/24"))"
}
variable "map_public_ip_on_launch" {
  type = "list"
  description = "Specifies whether the Subnet IDs should have a Public IP on Launch. Example: list("false")"
}
variable "public_subnet_name" {
  description = "Name of Public Subnet being created. Example : public"
}
variable "subnet_names_on_route_to_igw" {
  type = "list"
  description = "Names of the subnets to route to Internet Gateway. Public Subnets, in short. Example : list("public")"
}
variable "subnet_names_on_route_to_nat" {
  type = "list"
  description = "Names of the subnets to route to NAT Gateway. Private Subnets, in short. Example : list("private-1","private-2")"
}
variable "subnet_names_on_route_to_peer" {
  type = "list"
  description = "Names of the subnets to add routes to Monitoring and VPN Peer. Example : list("private-1","private-2")"
}
variable "ssh_changes_are_there" {
  description = "Any number or value to trigger a new pair of SSH Keys. Example: create1"
}
variable "key_name" {
  description = "Name of the SSH Key Pair. Example : server-access"
}
variable "generate_a_key" {
  description = "Indicates whether to generate the key or use existing one. Example: 1"
}
variable "associate_private_zones" {
  type = "list"
  description = "Private Route53 Zone domains to associate the VPC Created with. Example: example.local"
}
variable "what_connections_i_need" {
  type = "list"
  description = "Informs what connections needed for this VPC. Example : list("vpn-access","monitoring-access")"
}
variable "what_services_i_need" {
  type = "list"
  description = "Informs what AWS services needed for this VPC. Example: list("internetgateway","natgateway","ssh-key")"
}
variable "use_existing_vpc" {
  description = "Boolean to inform the terraform module to use existing VPC or create a new one . Example: false"
}
variable "generic_sg_name" {
  type = "list"
  description = "Security Group name to be created common to all nodes in the VPC. Example: list("vpc-sg")"
}

#KMS Key creation
variable "kms_key_name" {
  description = "Name of the KMS Key to create for Encrypting Vault ACL and Management Tokens created by Consul initial setup. Example: proj-consul"
}

#Slack Addition
variable "hook_url" {
  type = "list"
  description = "Slack HOOK URLs to upload to SSM. Example: list("hook-url-1")"
}

variable "slack_project_code" {
  type = "list"
  description = "Slack Project code for Lambda to identify the notification. Example: list("consul")"
}

variable "slack_channel" {
  type = "list"
  description = "Slack Channel names to send the notification to. Example: list("#consul-backup")"
}
