####################################################
# CREATE Necessary things for the ec2 instances
####################################################
data "template_file" "blue_instance_policy" {
  template = "${file("${var.consul_instance_policy["blue"]}")}"
  vars {
    backup_bucket_name = "${element(module.backup_bucket.bucket_id,0)}"
  }
}

data "template_file" "green_instance_policy" {
  template = "${file("${var.consul_instance_policy["green"]}")}"
  vars {
    backup_bucket_name = "${element(module.backup_bucket.bucket_id,0)}"
  }
}

#-------------------------------------------
### Creating the CONSUL SG
#--------------------------------------------
module "consul_sg" {
  source = "./security_group/sgs"
  sg_name = ["${var.sg_name["consul"]}"]
  project = "${var.project}"
  environment = "${var.environment}"
  vpc_id = "${data.terraform_remote_state.basic-infra.vpc_id}"
  description = "CONSUL SG ACCESS"
}

#-------------------------------------------
### SG INGRESS RULES
#--------------------------------------------
module "consul-tcp-ingress-rules" {
  source = "./security_group/rules/ingress/cidr_block"
  from_port = "${split(" ",local.consul_ports)}"
  to_port = "${split(" ",local.consul_ports)}"
  protocol = ["tcp"]
  cidr_blocks = ["${data.terraform_remote_state.basic-infra.vpc_cidr}"]
  security_group_id = "${module.consul_sg.sg_id[0]}"
}

module "consul-udp-ingress-rules" {
  source = "./security_group/rules/ingress/cidr_block"
  from_port = "${split(" ",local.consul_ports)}"
  to_port = "${split(" ",local.consul_ports)}"
  protocol = ["udp"]
  cidr_blocks = ["${data.terraform_remote_state.basic-infra.vpc_cidr}"]
  security_group_id = "${module.consul_sg.sg_id[0]}"
}

#-------------------------------------------
### SG EGRESS RULES
#--------------------------------------------
module "consul-tcp-egress-rules" {
  source = "./security_group/rules/egress/cidr_block"
  from_port = "${split(" ",local.consul_ports)}"
  to_port = "${split(" ",local.consul_ports)}"
  protocol = ["tcp"]
  cidr_blocks = ["${data.terraform_remote_state.basic-infra.vpc_cidr}"]
  security_group_id = "${module.consul_sg.sg_id[0]}"
}

module "consul-udp-egress-rules" {
  source = "./security_group/rules/egress/cidr_block"
  from_port = "${split(" ",local.consul_ports)}"
  to_port = "${split(" ",local.consul_ports)}"
  protocol = ["udp"]
  cidr_blocks = ["${data.terraform_remote_state.basic-infra.vpc_cidr}"]
  security_group_id = "${module.consul_sg.sg_id[0]}"
}

#-------------------------------------------
### SG UI Access
#--------------------------------------------
module "consul-ui-egress-rules" {
  source = "./security_group/rules/egress/cidr_block"
  from_port = ["${var.consul_https_port}"]
  to_port = ["${var.consul_https_port}"]
  protocol = ["tcp"]
  cidr_blocks = ["${data.terraform_remote_state.common_vpc.vpc_cidr}"]
  security_group_id = "${module.consul_sg.sg_id[0]}"
}

module "consul-ui-ingress-rules" {
  source = "./security_group/rules/ingress/cidr_block"
  from_port = ["${var.consul_https_port}"]
  to_port = ["${var.consul_https_port}"]
  protocol = ["tcp"]
  cidr_blocks = ["${data.terraform_remote_state.common_vpc.vpc_cidr}"]
  security_group_id = "${module.consul_sg.sg_id[0]}"
}

#-------------------------------------------
### EC2 Instances
#--------------------------------------------

module "blue-consul-servers" {
   source                 = "./ec2/multi-zone"
   should_i_create        = "${var.is_blue_mode_active == "yes" ? 1 : 0}"
   ami_id                 = "${data.aws_ami.recent_hardened_ami.id}"
   region                 = "${var.region}"
   instance_type          = "${var.consul_instance_type["blue"]}"
   iam_instance_policy    = "${data.template_file.blue_instance_policy.rendered}"
   security_groups        = ["${data.terraform_remote_state.basic-infra.generic_sg_id}","${module.consul_sg.sg_id}"]
   subnet_id              = "${data.terraform_remote_state.basic-infra.subnet_ids}"
   subnet_name_for_ec2    = "${var.subnet_to_build_for_consul["blue"]}"
   subnet_names           = "${var.subnet_names}"
   ssh_key_name           = "${element(data.terraform_remote_state.basic-infra.ssh_key_name,0)}"
   instance_name          = "blue-${var.instance_short_name["consul"]}"
   project                = "${var.project}"
   environment            = "${var.environment}"
   total_no_of_servers    = "${var.total_no_of_consul_servers["blue"]}"
   team                   = "${var.team}"
   availability_zones     = "${local.availability_zones}"
   rolename               = "blue-${var.ec2_role_names["consul"]}"
   instance_type_prefix   = "${var.consul_instance_prefix["blue"]}"
   user_data_base64              = ["${coalescelist(data.template_cloudinit_config.blue-user-data-file.*.rendered,local.empty_user_data)}"]
   custom_tags            = {
       AutoJoinConsul      = "${local.dc_name}"
       Mode                = "blue"
   }
   #For additional ebs volumes
   ami_disk_presents = "${var.ami_disk_presents["blue"]}"
   ebs_volume_size = "${var.consul_ebs_volume_size["blue"]}"
   ebs_volume_type = "${var.consul_ebs_volume_type["blue"]}"
   ebs_encrypted = "${var.consul_ebs_encrypted["blue"]}"
   number_of_block_devices = "${var.consul_number_of_ebs_devices["blue"]}"
}


module "green-consul-servers" {
   source                 = "./ec2/multi-zone"
   should_i_create        = "${var.is_green_mode_active == "yes" ? 1 : 0}"
   ami_id                 = "${data.aws_ami.recent_hardened_ami.id}"
   region                 = "${var.region}"
   instance_type          = "${var.consul_instance_type["green"]}"
   iam_instance_policy    = "${data.template_file.green_instance_policy.rendered}"
   security_groups        = ["${data.terraform_remote_state.basic-infra.generic_sg_id}","${module.consul_sg.sg_id}"]
   subnet_id              = "${data.terraform_remote_state.basic-infra.subnet_ids}"
   subnet_name_for_ec2    = "${var.subnet_to_build_for_consul["green"]}"
   subnet_names           = "${var.subnet_names}"
   ssh_key_name           = "${element(data.terraform_remote_state.basic-infra.ssh_key_name,0)}"
   instance_name          = "green-${var.instance_short_name["consul"]}"
   project                = "${var.project}"
   environment            = "${var.environment}"
   total_no_of_servers    = "${var.total_no_of_consul_servers["green"]}"
   team                   = "${var.team}"
   availability_zones     = "${local.availability_zones}"
   rolename               = "green-${var.ec2_role_names["consul"]}"
   instance_type_prefix   = "${var.consul_instance_prefix["green"]}"
   user_data_base64              = ["${coalescelist(data.template_cloudinit_config.green-user-data-file.*.rendered,local.empty_user_data)}"]
   custom_tags            = {
      AutoJoinConsul      = "${local.dc_name}"
      Mode                = "green"
   }
   #For additional ebs volumes
   ami_disk_presents = "${var.ami_disk_presents["green"]}"
   ebs_volume_size = "${var.consul_ebs_volume_size["green"]}"
   ebs_volume_type = "${var.consul_ebs_volume_type["green"]}"
   ebs_encrypted = "${var.consul_ebs_encrypted["green"]}"
   number_of_block_devices = "${var.consul_number_of_ebs_devices["green"]}"
}


data null_data_source "blue-servers-A-records" {
  count = "${var.total_no_of_consul_servers["blue"]}"
  inputs = {
    record_name = "blue-${var.environment}-${var.instance_short_name["consul"]}-${count.index}"
  }
}

data null_data_source "green-servers-A-records" {
  count = "${var.total_no_of_consul_servers["green"]}"
  inputs = {
    record_name = "green-${var.environment}-${var.instance_short_name["consul"]}-${count.index}"
  }
}

module "blue-server-A-records" {
  source = "./route53/simple_routing_policy/multi"
  should_i_create = "${var.is_blue_mode_active == "yes" ? 1 : 0}"
  route53_zone = ["${data.terraform_remote_state.basic-infra.zone_id}"]
  record_name  = ["${data.null_data_source.blue-servers-A-records.*.outputs.record_name}"]
  record_type = ["A"]
  record_entry = "${chunklist(module.blue-consul-servers.private_ip,1)}"
}

module "green-server-A-records" {
  source = "./route53/simple_routing_policy/multi"
  should_i_create = "${var.is_green_mode_active == "yes" ? 1 : 0}"
  route53_zone =  ["${data.terraform_remote_state.basic-infra.zone_id}"]
  record_name  = ["${data.null_data_source.green-servers-A-records.*.outputs.record_name}"]
  record_type = ["A"]
  record_entry = "${chunklist(module.green-consul-servers.private_ip,1)}"
}



module "blue-server-common-A-record" {
  source = "./route53/simple_routing_policy/multi"
  should_i_create = "${var.is_blue_mode_active == "yes" ? 1 : 0}"
  route53_zone = ["${data.terraform_remote_state.basic-infra.zone_id}"]
  record_name  = ["blue-${var.environment}-${var.instance_short_name["consul"]}"]
  record_type = ["A"]
  #record_entry = "${chunklist(formatlist("%s%s",data.null_data_source.blue-servers-A-records.*.outputs.record_name,".${var.dhcp_domain}"),1)}"
  record_entry = "${chunklist(module.blue-consul-servers.private_ip,var.total_no_of_consul_servers["blue"])}"
}

module "green-server-common-A-record" {
  source = "./route53/simple_routing_policy/multi"
  should_i_create = "${var.is_green_mode_active == "yes" ? 1 : 0}"
  route53_zone = ["${data.terraform_remote_state.basic-infra.zone_id}"]
  record_name  = ["green-${var.environment}-${var.instance_short_name["consul"]}"]
  record_type = ["A"]
  #record_entry = "${chunklist(formatlist("%s%s",data.null_data_source.green-servers-A-records.*.outputs.record_name,".${var.dhcp_domain}"),1)}"
  record_entry = "${chunklist(module.green-consul-servers.private_ip,var.total_no_of_consul_servers["green"])}"
}

module "attach-server-blue-cname" {
  source = "./route53/simple_routing_policy/multi"
  should_i_create = "${var.is_blue_mode_active == "yes" && var.keep_dns_deployment_mode == "blue" ? 1 : 0}"
  route53_zone = ["${data.terraform_remote_state.basic-infra.zone_id}"]
  record_name  = ["${var.environment}-${var.instance_short_name["consul"]}"]
  record_type = ["CNAME"]
  record_entry = "${chunklist(local.blue_common_name,1)}"
}

module "attach-server-green-cname" {
  source = "./route53/simple_routing_policy/multi"
  should_i_create = "${var.is_green_mode_active == "yes" && var.keep_dns_deployment_mode == "green" ? 1 : 0}"
  route53_zone = ["${data.terraform_remote_state.basic-infra.zone_id}"]
  record_name  = ["${var.environment}-${var.instance_short_name["consul"]}"]
  record_type = ["CNAME"]
  record_entry = "${chunklist(local.green_common_name,1)}"
}
