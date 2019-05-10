data "aws_availability_zones" "region" {
  state = "available"
}

module "vault-basic-infra" {
  source = "./burbank-basic-infra"
  use_existing_vpc = "${var.use_existing_vpc}"
  project = "${var.environment == "dev" ? var.common_dev_project : var.project}"
  environment = "${var.environment == "dev" ? var.common_dev_environment : var.environment}"
  subnet_names = "${var.subnet_names}"
  region = "${var.region}"
  common_project = "${var.common_project}"
  common_environment = "${var.common_environment}"
  generic_sg_name   = "${var.generic_sg_name}"
  availability_zones = "${data.aws_availability_zones.region.names}"
  cidr_block = "${var.cidr_block}"
  dhcp_domain = "${var.dhcp_domain}"
  subnet_cidr_block = "${var.subnet_cidr_block}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"
  public_subnet_name = "${var.public_subnet_name}"
  subnet_names_on_route_to_igw = "${var.subnet_names_on_route_to_igw}"
  subnet_names_on_route_to_nat = "${var.subnet_names_on_route_to_nat}"
  subnet_names_on_route_to_peer = "${var.subnet_names_on_route_to_peer}"
  ssh_changes_are_there = "${var.ssh_changes_are_there}"
  key_name = "${var.key_name}"
  associate_private_zones = "${var.associate_private_zones}"
  what_services_i_need = "${var.what_services_i_need}"
  what_connections_i_need = "${var.what_connections_i_need}"
  # This is applicable only for Dev environment. Passing it for other environments have no effect
  existing_ssh_terraform_path = "${var.existing_ssh_terraform_path}"
}

#---------------------------------------------------------------------
# Create a Key for keeping Vault management tokens and Vault ACL token
#---------------------------------------------------------------------
module "kms_key" {
  source = "./kms/create_key"
  environment = "${var.environment}"
  region = "${var.region}"
  project = "${var.project}"
  kms_key_name = "${var.kms_key_name}"
}

#---------------------------------------------------------------------
# Consul Backup Slack Notifier
#---------------------------------------------------------------------
module "slack_table" {
  source = "./slack"
  region = "${var.region}"
  common_project = "${var.common_project}"
  common_environment = "${var.common_environment}"
  slack_project_code = "${var.slack_project_code}"
  hook_url = "${var.hook_url}"
  slack_channel = "${var.slack_channel}"
  project = "${var.project}"
  environment = "${var.environment}"
}
