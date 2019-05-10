####################################################
# GET THE STATE OF BASIC INFRA
####################################################
data "aws_availability_zone" "region" {
  count = "${var.environment == "dev" ? 1 : 0}"
  name  = "${var.dev_availability_zone}"
  state = "available"
}

data "aws_availability_zones" "multi" {
  state = "available"
}


data "terraform_remote_state" "basic-infra" {
   backend = "s3"
   config {
       bucket = "tf-${var.region}-terraform-${var.project}-${var.environment}"
       key    = "${var.basic_infra_terraform_state}"
       region = "${var.region}"
   }
}

data "terraform_remote_state" "slack_topic" {
   backend = "s3"
   config {
       bucket = "tf-${var.region}-terraform-${var.common_project}-${var.common_environment}"
       key    = "${var.slack_topic_terraform_state}"
       region = "${var.region}"
   }
}

data "terraform_remote_state" "common_vpc" {
   backend = "s3"
   config {
       bucket = "tf-${var.region}-terraform-${var.common_project}-${var.common_environment}"
       key    = "${var.common_vpc_terraform_state}"
       region = "${var.region}"
   }
}

#-------------------------------------------------------------
### Getting the current account id
#-------------------------------------------------------------
data "aws_caller_identity" "current" {}

#-------------------------------------------------------------
### Getting the latest hardened OS image
#-------------------------------------------------------------
data "aws_ami" "recent_hardened_ami" {
  most_recent = true

 filter {
    name   = "name"
    values = ["${var.hardened_ami_name}"]
  }

 filter {
    name   = "architecture"
    values = ["${var.hardened_ami_architecture}"]
  }

 filter {
    name   = "virtualization-type"
    values = ["${var.hardened_ami_virt_type}"]
  }
  owners = ["${data.aws_caller_identity.current.account_id}"]
}
