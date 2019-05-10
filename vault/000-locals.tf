##################################################################
# Construct Local Variables to use with this vault infrastructure
##################################################################
locals {
  dc_name = "${data.terraform_remote_state.consul.dc_name}"
}
locals {
  availability_zones = "${coalescelist(data.aws_availability_zone.region.*.name,data.aws_availability_zones.multi.names)}"

  dns_server_entry_prefix = {
    blue = "blue-${var.environment}-${var.instance_short_name["vault"]}"
    green = "green-${var.environment}-${var.instance_short_name["vault"]}"
  }
  dns_cname = {
    blue = "blue-${var.environment}-${var.instance_short_name["vault"]}.${var.dhcp_domain}"
    green = "green-${var.environment}-${var.instance_short_name["vault"]}.${var.dhcp_domain}"
    common = "${var.environment}-${var.instance_short_name["vault"]}.${var.dhcp_domain}"
  }
  dns_consul_client_entry_prefix = {
    blue = "blue-${var.environment}-vault-consul-client"
    green = "green-${var.environment}-vault-consul-client"
  }

  len_blue_user_data = "${length(var.blue_vault_user_data_scripts)}"
  len_blue_servers = "${var.total_no_of_vault_servers["blue"]}"
  len_green_user_data = "${length(var.green_vault_user_data_scripts)}"
  len_green_servers = "${var.total_no_of_vault_servers["green"]}"

  empty_user_data = ["dontcreate"]

  vault_backend_token_name = "${local.dc_name}-${var.vault_backend_token_name}"
  consul_agent_token_name = "${local.dc_name}-${var.consul_token_parameters["consul_agent_token_name"]}"
  consul_agent_master_token_name  = "${local.dc_name}-${var.consul_token_parameters["consul_agent_master_token_name"]}"

  vault_ports = "${var.vault_port} ${var.vault_cluster_port}"
  vault_cert_names = ["vault-server","vault-consul-agent","vault-consul-client"]
}
