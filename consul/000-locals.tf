# Putting all locals in one place. Easy to debug
locals {
  availability_zones = "${coalescelist(data.aws_availability_zone.region.*.name,data.aws_availability_zones.multi.names)}"

  dns_server_entry_prefix = {
    blue = "blue-${var.environment}-${var.instance_short_name["consul"]}"
    green = "green-${var.environment}-${var.instance_short_name["consul"]}"
  }

  dns_cname = {
    blue = "blue-${var.environment}-${var.instance_short_name["consul"]}.${var.dhcp_domain}"
    green = "green-${var.environment}-${var.instance_short_name["consul"]}.${var.dhcp_domain}"
    common = "${var.environment}-${var.instance_short_name["consul"]}.${var.dhcp_domain}"
  }

  consul_verify_server_name = "server.${var.consul_dc_name_prefix}-${var.environment}.${var.consul_domain_name}"

  dc_name = "${var.consul_dc_name_prefix}-${var.environment}"

  len_blue_user_data = "${length(var.blue_consul_user_data_scripts)}"
  len_blue_servers = "${var.total_no_of_consul_servers["blue"]}"
  len_green_user_data = "${length(var.green_consul_user_data_scripts)}"
  len_green_servers = "${var.total_no_of_consul_servers["green"]}"

  empty_user_data = ["empty"]

  blue_common_name = ["blue-${var.environment}-${var.instance_short_name["consul"]}.${var.dhcp_domain}"]
  green_common_name = ["green-${var.environment}-${var.instance_short_name["consul"]}.${var.dhcp_domain}"]

  consul_ports = "${format("%s%s%s",var.consul_https_port," ",var.consul_ports)}"
}


#Do not change this , as Vault will not work if any of this is changed
locals {
  consul_agent_token_name = "${local.dc_name}-${var.consul_token_parameters["consul_agent_token_name"]}"
  consul_agent_master_token_name  = "${local.dc_name}-${var.consul_token_parameters["consul_agent_master_token_name"]}"
  consul_replication_token_name = "${local.dc_name}-${var.consul_token_parameters["consul_replication_token_name"]}"
  consul_for_vault_management_token_name = "${local.dc_name}-${var.consul_token_parameters["consul_management_name"]}"
  vault_backend_token_name = "${local.dc_name}-${var.vault_backend_token_name}"
}
