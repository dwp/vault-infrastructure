data "aws_ip_ranges" "us-east-1-iam" {
  regions = ["us-east-1"]
  services = ["amazon"]
}

####################################################
# CREATE Necessary things for the ec2 instances
####################################################
data "template_file" "blue_instance_policy" {
  template = "${file("${var.vault_instance_policy["blue"]}")}"
  vars {
    region = "${var.region}"
    project = "${var.project}"
    environment = "${var.environment}"
    backup_bucket_name = "${element(data.terraform_remote_state.consul.backup_bucket_name,0)}"
  }
}

data "template_file" "green_instance_policy" {
  template = "${file("${var.vault_instance_policy["green"]}")}"
  vars {
    region = "${var.region}"
    project = "${var.project}"
    environment = "${var.environment}"
    backup_bucket_name = "${element(data.terraform_remote_state.consul.backup_bucket_name,0)}"
  }
}

####################################################
# CREATE necessary things for the Lambda Function
####################################################
module "lambda_role" {
  source = "./iam/role"
  project  = "${var.project}"
  environment = "${var.environment}"
  rolename = "${var.vault_lambda_role_name}"
  policyfile = "${var.vault_lambda_role_sts_file}"
}

data "template_file" "lambda_policy" {
  template = "${file(var.vault_lambda_policy_file)}"
  vars {
    region = "${var.region}"
    vault_token_ssm_path = "${var.vault_token_ssm_path}"
  }
}

module "lambda_policy" {
  source = "./iam/rolepolicy"
  project = "${var.project}"
  environment = "${var.environment}"
  policyname  = "${var.vault_lambda_policy_name}"
  policyfile  = "${data.template_file.lambda_policy.rendered}"
  rolename    = "${module.lambda_role.iamrole_name[0]}"
}

####################################################
# Grant Permissions to the KMS key created
####################################################
module "blue_kms_grant" {
  source = "./kms/grant_access"
  should_i_create = "${var.is_blue_mode_active == "yes" ? 1 : 0}"
  grant_name = ["blue-${var.environment}-${var.instance_short_name["vault"]}-grant"]
  kms_key_id = "${data.terraform_remote_state.basic-infra.kms_key_id}"
  grant_principals = "${module.blue-vault-servers.iamrole_arn}"
  operations = "${var.vault_kms_grant_operations["blue"]}"
}

module "green_kms_grant" {
  source = "./kms/grant_access"
  should_i_create = "${var.is_green_mode_active == "yes" ? 1 : 0}"
  grant_name = ["green-${var.environment}-${var.instance_short_name["vault"]}-grant"]
  kms_key_id = "${data.terraform_remote_state.basic-infra.kms_key_id}"
  grant_principals = "${module.green-vault-servers.iamrole_arn}"
  operations = "${var.vault_kms_grant_operations["green"]}"
}

#-------------------------------------------
### Give access to Unseal
#--------------------------------------------
module "unseal_key_access" {
  source = "./kms/grant_access"
  grant_name = ["${local.dc_name}-vault-unseal-key-grant"]
  kms_key_id = "${module.unseal_kms_key.kms_key_id}"
  grant_principals = "${module.green-vault-servers.iamrole_arn}"
  operations = ["Encrypt","Decrypt","DescribeKey"]
}

#-------------------------------------------
### Creating the vault SG
#--------------------------------------------
module "vault_sg" {
  source = "./security_group/sgs"
  sg_name = ["${var.sg_name["vault"]}"]
  project = "${var.project}"
  environment = "${var.environment}"
  vpc_id = "${data.terraform_remote_state.basic-infra.vpc_id}"
  description = "vault SG ACCESS"
}

#-------------------------------------------
### SG INGRESS RULES
#--------------------------------------------
module "vault-tcp-ingress-rules" {
  source = "./security_group/rules/ingress/cidr_block"
  from_port = "${split(" ",local.vault_ports)}"
  to_port = "${split(" ",local.vault_ports)}"
  protocol = ["tcp"]
  cidr_blocks = ["${data.terraform_remote_state.basic-infra.vpc_cidr}"]
  security_group_id = "${module.vault_sg.sg_id[0]}"
}

module "vault-tcp-egress-rules" {
  source = "./security_group/rules/egress/cidr_block"
  from_port = "${split(" ",local.vault_ports)}"
  to_port = "${split(" ",local.vault_ports)}"
  protocol = ["tcp"]
  cidr_blocks = ["${data.terraform_remote_state.basic-infra.vpc_cidr}"]
  security_group_id = "${module.vault_sg.sg_id[0]}"
}

module "vault-tcp-ingress-rules-vpn" {
  source = "./security_group/rules/ingress/cidr_block"
  from_port = ["${var.vault_port}"]
  to_port = ["${var.vault_port}"]
  protocol = ["tcp"]
  cidr_blocks = ["${data.terraform_remote_state.common.vpc_cidr}"]
  security_group_id = "${module.vault_sg.sg_id[0]}"
}

module "blue-vault-servers" {
   source                 = "./ec2/multi-zone"
   should_i_create        = "${var.is_blue_mode_active == "yes" ? 1 : 0}"
   ami_id                 = "${data.aws_ami.recent_hardened_ami.id}"
   region                 = "${var.region}"
   instance_type          = "${var.vault_instance_type["blue"]}"
   iam_instance_policy    = "${data.template_file.blue_instance_policy.rendered}"
   security_groups        = ["${data.terraform_remote_state.basic-infra.generic_sg_id}","${module.vault_sg.sg_id}","${data.terraform_remote_state.consul.consul_sg_id}"]
   subnet_id              = "${data.terraform_remote_state.basic-infra.subnet_ids}"
   subnet_name_for_ec2    = "${var.subnet_to_build_for_vault["blue"]}"
   subnet_names           = "${var.subnet_names}"
   ssh_key_name           = "${element(data.terraform_remote_state.basic-infra.ssh_key_name,0)}"
   instance_name          = "blue-${var.instance_short_name["vault"]}"
   project                = "${var.project}"
   environment            = "${var.environment}"
   total_no_of_servers    = "${var.total_no_of_vault_servers["blue"]}"
   team                   = "${var.team}"
   availability_zones     = "${local.availability_zones}"
   rolename               = "blue-${var.ec2_role_names["vault"]}"
   instance_type_prefix   = "${var.vault_instance_prefix["blue"]}"
   user_data_base64       = ["${coalescelist(data.template_cloudinit_config.blue-user-data-file.*.rendered,local.empty_user_data)}"]
   custom_tags            = {
        Mode                = "blue"
   }
    custom_audit_log_path  = ["${var.green_vault_user_data_config["vault_audit_log_file_path"]}"]
    custom_audit_log_path_stream_name = ["vault-audit-log"]
    #For additional ebs volumes
    ami_disk_presents = "${var.ami_disk_presents["blue"]}"
    ebs_volume_size = "${var.vault_ebs_volume_size["blue"]}"
    ebs_volume_type = "${var.vault_ebs_volume_type["blue"]}"
    ebs_encrypted = "${var.vault_ebs_encrypted["blue"]}"
    number_of_block_devices = "${var.vault_number_of_ebs_devices["blue"]}"
}

module "green-vault-servers" {
   source                 = "./ec2/multi-zone"
   should_i_create        = "${var.is_green_mode_active == "yes" ? 1 : 0}"
   ami_id                 = "${data.aws_ami.recent_hardened_ami.id}"
   region                 = "${var.region}"
   instance_type          = "${var.vault_instance_type["green"]}"
   iam_instance_policy    = "${data.template_file.green_instance_policy.rendered}"
   security_groups        = ["${data.terraform_remote_state.basic-infra.generic_sg_id}","${module.vault_sg.sg_id}","${data.terraform_remote_state.consul.consul_sg_id}"]
   subnet_id              = "${data.terraform_remote_state.basic-infra.subnet_ids}"
   subnet_name_for_ec2    = "${var.subnet_to_build_for_vault["green"]}"
   subnet_names           = "${var.subnet_names}"
   ssh_key_name           = "${element(data.terraform_remote_state.basic-infra.ssh_key_name,0)}"
   instance_name          = "green-${var.instance_short_name["vault"]}"
   project                = "${var.project}"
   environment            = "${var.environment}"
   total_no_of_servers    = "${var.total_no_of_vault_servers["green"]}"
   team                   = "${var.team}"
   availability_zones     = "${local.availability_zones}"
   rolename               = "green-${var.ec2_role_names["vault"]}"
   instance_type_prefix   = "${var.vault_instance_prefix["green"]}"
   user_data_base64       = ["${coalescelist(data.template_cloudinit_config.green-user-data-file.*.rendered,local.empty_user_data)}"]
   custom_tags            = {
        Mode                = "green"
   }
   custom_audit_log_path  = ["${var.green_vault_user_data_config["vault_audit_log_file_path"]}"]
   custom_audit_log_path_stream_name = ["vault-audit-log"]
    #For additional ebs volumes
    ami_disk_presents = "${var.ami_disk_presents["green"]}"
    ebs_volume_size = "${var.vault_ebs_volume_size["green"]}"
    ebs_volume_type = "${var.vault_ebs_volume_type["green"]}"
    ebs_encrypted = "${var.vault_ebs_encrypted["green"]}"
    number_of_block_devices = "${var.vault_number_of_ebs_devices["green"]}"
}

data null_data_source "blue-servers-A-records" {
  count = "${var.total_no_of_vault_servers["blue"]}"
  inputs = {
    record_name = "blue-${var.environment}-${var.instance_short_name["vault"]}-${count.index}"
  }
}

data null_data_source "green-servers-A-records" {
  count = "${var.total_no_of_vault_servers["green"]}"
  inputs = {
    record_name = "green-${var.environment}-${var.instance_short_name["vault"]}-${count.index}"
  }
}


module "blue-server-A-records" {
  source = "./route53/simple_routing_policy/multi"
  should_i_create = "${var.is_blue_mode_active == "yes" ? 1 : 0}"
  route53_zone = ["${data.terraform_remote_state.basic-infra.zone_id}"]
  record_name  = ["${data.null_data_source.blue-servers-A-records.*.outputs.record_name}"]
  record_type = ["A"]
  record_entry = "${chunklist(module.blue-vault-servers.private_ip,1)}"
}

module "green-server-A-records" {
  source = "./route53/simple_routing_policy/multi"
  should_i_create = "${var.is_green_mode_active == "yes" ? 1 : 0}"
  route53_zone =  ["${data.terraform_remote_state.basic-infra.zone_id}"]
  record_name  = ["${data.null_data_source.green-servers-A-records.*.outputs.record_name}"]
  record_type = ["A"]
  record_entry = "${chunklist(module.green-vault-servers.private_ip,1)}"
}



module "blue-server-common-A-record" {
  source = "./route53/simple_routing_policy/multi"
  should_i_create = "${var.is_blue_mode_active == "yes" ? 1 : 0}"
  route53_zone = ["${data.terraform_remote_state.basic-infra.zone_id}"]
  record_name  = ["blue-${var.environment}-${var.instance_short_name["vault"]}"]
  record_type = ["A"]
  #record_entry = "${chunklist(formatlist("%s%s",data.null_data_source.blue-servers-A-records.*.outputs.record_name,".${var.dhcp_domain}"),1)}"
  record_entry = "${chunklist(module.blue-vault-servers.private_ip,var.total_no_of_vault_servers["blue"])}"
}

module "green-server-common-A-record" {
  source = "./route53/simple_routing_policy/multi"
  should_i_create = "${var.is_green_mode_active == "yes" ? 1 : 0}"
  route53_zone = ["${data.terraform_remote_state.basic-infra.zone_id}"]
  record_name  = ["green-${var.environment}-${var.instance_short_name["vault"]}"]
  record_type = ["A"]
  #record_entry = "${chunklist(formatlist("%s%s",data.null_data_source.green-servers-A-records.*.outputs.record_name,".${var.dhcp_domain}"),1)}"
  record_entry = "${chunklist(module.green-vault-servers.private_ip,var.total_no_of_vault_servers["green"])}"
}

module "attach-server-blue-cname" {
  source = "./route53/simple_routing_policy/multi"
  should_i_create = "${var.is_blue_mode_active == "yes" && var.keep_dns_deployment_mode == "blue" ? 1 : 0}"
  route53_zone = ["${data.terraform_remote_state.basic-infra.zone_id}"]
  record_name  = ["${var.environment}-${var.instance_short_name["vault"]}"]
  record_type = ["CNAME"]
  record_entry = ["${local.dns_cname["blue"]}"]
}

module "attach-server-green-cname" {
  source = "./route53/simple_routing_policy/multi"
  should_i_create = "${var.is_green_mode_active == "yes" && var.keep_dns_deployment_mode == "green" ? 1 : 0}"
  route53_zone = ["${data.terraform_remote_state.basic-infra.zone_id}"]
  record_name  = ["${var.environment}-${var.instance_short_name["vault"]}"]
  record_type = ["CNAME"]
  record_entry = ["${local.dns_cname["green"]}"]
}
