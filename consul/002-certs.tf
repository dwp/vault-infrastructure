
#-------------------------------------------------------------
### Setting the common name for the applications
#-------------------------------------------------------------
data "null_data_source" "blue-common-name" {
  count = "${var.total_no_of_consul_servers["blue"]}"
  inputs = {
    common_name = "${local.dns_server_entry_prefix["blue"]}-${count.index}.${var.dhcp_domain}"
  }
}

data "null_data_source" "green-common-name" {
  count = "${var.total_no_of_consul_servers["green"]}"
  inputs = {
    common_name = "${local.dns_server_entry_prefix["green"]}-${count.index}.${var.dhcp_domain}"
  }
}


# For BLUE Consul Server Agent and BLUE Consul Server Client certificates
module "blue_consul_server_cert_key" {
  source = "./tls/private_key"
  no_of_keys = "${var.total_no_of_consul_servers["blue"]}"
  algorithm = "${var.cert_algorithm["consul"]}"
  rsa_key_size = "${var.cert_key_length["consul"]}"
}

module "blue_consul_server_csr" {
  source = "./tls/csr"
  algorithm = "${var.cert_algorithm["consul"]}"
  no_of_keys = "${var.total_no_of_consul_servers["blue"]}"
  private_keys = "${module.blue_consul_server_cert_key.private_key_pem}"
  dns_names = ["${local.dns_cname["blue"]}","${local.dns_cname["common"]}","${local.consul_verify_server_name}"]
  common_name = ["${data.null_data_source.blue-common-name.*.outputs.common_name}"]
}

module "blue_consul_client_cert_key" {
  source = "./tls/private_key"
  no_of_keys = "${var.total_no_of_consul_servers["blue"]}"
  algorithm = "${var.cert_algorithm["consul"]}"
  rsa_key_size = "${var.cert_key_length["consul"]}"
}

module "blue_consul_client_csr" {
  source = "./tls/csr"
  algorithm = "${var.cert_algorithm["consul"]}"
  no_of_keys = "${var.total_no_of_consul_servers["blue"]}"
  private_keys = "${module.blue_consul_client_cert_key.private_key_pem}"
  common_name = ["${data.null_data_source.blue-common-name.*.outputs.common_name}"]
}

# For GREEN Consul Server Agent and GREEN Consul Server Client certificates
module "green_consul_server_cert_key" {
  source = "./tls/private_key"
  no_of_keys = "${var.total_no_of_consul_servers["green"]}"
  algorithm = "${var.cert_algorithm["consul"]}"
  rsa_key_size = "${var.cert_key_length["consul"]}"
}

module "green_consul_server_csr" {
  source = "./tls/csr"
  algorithm = "${var.cert_algorithm["consul"]}"
  no_of_keys = "${var.total_no_of_consul_servers["green"]}"
  private_keys = "${module.green_consul_server_cert_key.private_key_pem}"
  dns_names = ["${local.dns_cname["green"]}","${local.dns_cname["common"]}","${local.consul_verify_server_name}"]
  common_name = ["${data.null_data_source.green-common-name.*.outputs.common_name}"]
}

module "green_consul_client_cert_key" {
  source = "./tls/private_key"
  no_of_keys = "${var.total_no_of_consul_servers["green"]}"
  algorithm = "${var.cert_algorithm["consul"]}"
  rsa_key_size = "${var.cert_key_length["consul"]}"
}

module "green_consul_client_csr" {
  source = "./tls/csr"
  algorithm = "${var.cert_algorithm["consul"]}"
  no_of_keys = "${var.total_no_of_consul_servers["green"]}"
  private_keys = "${module.green_consul_client_cert_key.private_key_pem}"
  common_name = ["${data.null_data_source.green-common-name.*.outputs.common_name}"]
}
