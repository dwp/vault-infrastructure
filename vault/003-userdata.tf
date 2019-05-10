# Random UUID Generator
resource "random_uuid" "uuids" {}

#-------------------------------------------------------------
# Upload the Certs to SSM. As User data is failing for the size limit
#-------------------------------------------------------------
data "null_data_source" "blue_vault_certs" {
  count = "${length(local.vault_cert_names) * local.len_blue_servers}"
  inputs = {
    cert_names = "/certs/${var.project}/${var.environment}/blue-${local.vault_cert_names[count.index / local.len_blue_servers]}-${count.index % local.len_blue_servers}-cert"
    cert_values = "${file("certs/blue-${local.vault_cert_names[count.index / local.len_blue_servers]}-${count.index % local.len_blue_servers}.crt")}"
  }
}

data "null_data_source" "green_vault_certs" {
  count = "${length(local.vault_cert_names) * local.len_green_servers}"
  inputs = {
    cert_names = "/certs/${var.project}/${var.environment}/green-${local.vault_cert_names[count.index / local.len_green_servers]}-${count.index % local.len_green_servers}-cert"
    cert_values = "${file("certs/green-${local.vault_cert_names[count.index / local.len_green_servers]}-${count.index % local.len_green_servers}.crt")}"
  }
}

module "blue_certs_keys_upload" {
  source = "./ssm/parameter"
  should_i_create = "${var.is_blue_mode_active == "yes" ? 1 : 0}"
  ssm_name = "${data.null_data_source.blue_vault_certs.*.outputs.cert_names}"
  ssm_type = ["SecureString"]
  ssm_value = "${data.null_data_source.blue_vault_certs.*.outputs.cert_values}"
  ssm_description = ["blue-${var.project}-${var.environment}-certs-and-keys"]
  ssm_keyid = "${data.terraform_remote_state.basic-infra.kms_key_id[0]}"
  ssm_overwrite = "true"
  project = "${var.project}"
  environment = "${var.environment}"
}

module "green_certs_keys_upload" {
  source = "./ssm/parameter"
  should_i_create = "${var.is_green_mode_active == "yes" ? 1 : 0}"
  ssm_name = "${data.null_data_source.green_vault_certs.*.outputs.cert_names}"
  ssm_type = ["SecureString"]
  ssm_value = "${data.null_data_source.green_vault_certs.*.outputs.cert_values}"
  ssm_description = ["green-${var.project}-${var.environment}-certs-and-keys"]
  ssm_keyid = "${data.terraform_remote_state.basic-infra.kms_key_id[0]}"
  ssm_overwrite = "true"
  project = "${var.project}"
  environment = "${var.environment}"
}

#Upload the initial policies to SSM. As it is not picking up as a file
data "null_data_source" "blue_initial_config_names" {
  count = "${length(var.blue_vault_policies)}"
  inputs = {
    ssm_names = "/vault-init-config/${var.project}/${var.environment}/blue-${var.blue_vault_policies[count.index]}"
    ssm_values = "${file("${var.blue_vault_policy_dir}/${var.blue_vault_policies[count.index]}.hcl")}"
  }
}
module "blue_vault_policies_to_ssm" {
  source = "./ssm/parameter"
  should_i_create = "${var.is_blue_mode_active == "yes" ? 1 : 0}"
  ssm_name = "${data.null_data_source.blue_initial_config_names.*.outputs.ssm_names}"
  ssm_type = ["String"]
  ssm_value = "${data.null_data_source.blue_initial_config_names.*.outputs.ssm_values}"
  ssm_description = ["blue-${var.project}-${var.environment}-vault-initial-policies"]
  ssm_overwrite = "true"
  project = "${var.project}"
  environment = "${var.environment}"
}

data "null_data_source" "green_initial_config_names" {
  count = "${length(var.green_vault_policies)}"
  inputs = {
    ssm_names = "/vault-init-config/${var.project}/${var.environment}/green-${var.green_vault_policies[count.index]}"
    ssm_values = "${file("${var.green_vault_policy_dir}/${var.green_vault_policies[count.index]}.hcl")}"
  }
}

module "green_vault_policies_to_ssm" {
  source = "./ssm/parameter"
  should_i_create = "${var.is_green_mode_active == "yes" ? 1 : 0}"
  ssm_name = "${data.null_data_source.green_initial_config_names.*.outputs.ssm_names}"
  ssm_type = ["String"]
  ssm_value = "${data.null_data_source.green_initial_config_names.*.outputs.ssm_values}"
  ssm_description = ["green-${var.project}-${var.environment}-vault-initial-policies"]
  ssm_overwrite = "true"
  project = "${var.project}"
  environment = "${var.environment}"
}

#-------------------------------------------------------------
### Create a KMS Key for the Unseal
#-------------------------------------------------------------
module "unseal_kms_key" {
  source = "./kms/create_key"
  project = "${var.project}"
  environment = "${var.environment}"
  region = "${var.region}"
  kms_key_name = "${local.dc_name}-vault-unseal-key"
}


#-------------------------------------------------------------
### Template the Consul Config File
#-------------------------------------------------------------
data "template_file" "blue_consul_config" {
  count = "${var.is_blue_mode_active == "yes" ? var.total_no_of_vault_servers["blue"] : 0}"
  template = "${file("${var.blue_vault_config_parameters["consul_config_template"]}")}"
  vars {
    dc_name = "${local.dc_name}"
    acl_default_policy = "${var.blue_vault_consul_agent_config_parameters["acl_default_policy"]}"
    acl_down_policy = "${var.blue_vault_consul_agent_config_parameters["acl_down_policy"]}"
    autopilot_cleanup_dead_servers = "${var.blue_vault_consul_agent_config_parameters["autopilot_cleanup_dead_servers"]}"
    autopilot_last_contact_threshold = "${var.blue_vault_consul_agent_config_parameters["autopilot_last_contact_threshold"]}"
    autopilot_max_trailing_logs = "${var.blue_vault_consul_agent_config_parameters["autopilot_max_trailing_logs"]}"
    autopilot_server_stablization_time = "${var.blue_vault_consul_agent_config_parameters["autopilot_server_stablization_time"]}"
    autopilot_disable_upgrade_migration = "${var.blue_vault_consul_agent_config_parameters["autopilot_disable_upgrade_migration"]}"
    number_of_consul_servers = "${var.total_no_of_vault_servers["blue"]}"
    ca_path = "${var.blue_vault_consul_agent_config_parameters["ca_path"]}"
    server_cert_file = "${var.blue_vault_consul_agent_config_parameters["ssl_path"]}/${var.blue_vault_config_parameters["consul_agent_cert_name"]}"
    check_update_interval = "${var.blue_vault_consul_agent_config_parameters["check_update_interval"]}"
    data_dir = "${var.blue_vault_consul_agent_config_parameters["data_dir"]}"
    disable_anonymous_signature = "${var.blue_vault_consul_agent_config_parameters["disable_anonymous_signature"]}"
    disable_http_unprintable_char_filter = "${var.blue_vault_consul_agent_config_parameters["disable_http_unprintable_char_filter"]}"
    disable_remote_exec = "${var.blue_vault_consul_agent_config_parameters["disable_remote_exec"]}"
    disable_update_check = "${var.blue_vault_consul_agent_config_parameters["disable_update_check"]}"
    discard_check_output = "${var.blue_vault_consul_agent_config_parameters["discard_check_output"]}"
    discovery_max_stale = "${var.blue_vault_consul_agent_config_parameters["discovery_max_stale"]}"
    dns_config_allow_stale = "${var.blue_vault_consul_agent_config_parameters["dns_config_allow_stale"]}"
    dns_config_max_stale = "${var.blue_vault_consul_agent_config_parameters["dns_config_max_stale"]}"
    dns_config_node_ttl = "${var.blue_vault_consul_agent_config_parameters["dns_config_node_ttl"]}"
    dns_config_enable_truncate = "${var.blue_vault_consul_agent_config_parameters["dns_config_enable_truncate"]}"
    dns_config_only_passing = "${var.blue_vault_consul_agent_config_parameters["dns_config_only_passing"]}"
    dns_config_recursor_timeout = "${var.blue_vault_consul_agent_config_parameters["dns_config_recursor_timeout"]}"
    dns_config_disable_compression = "${var.blue_vault_consul_agent_config_parameters["dns_config_disable_compression"]}"
    domain_name = "${var.dhcp_domain}"
    enable_acl_replication = "${var.blue_vault_consul_agent_config_parameters["enable_acl_replication"]}"
    enable_agent_tls_for_checks = "${var.blue_vault_consul_agent_config_parameters["enable_agent_tls_for_checks"]}"
    enable_debug = "${var.blue_vault_consul_agent_config_parameters["enable_debug"]}"
    enable_syslog = "${var.blue_vault_consul_agent_config_parameters["enable_syslog"]}"
    encrypt_verify_incoming = "${var.blue_vault_consul_agent_config_parameters["encrypt_verify_incoming"]}"
    encrypt_verify_outgoing = "${var.blue_vault_consul_agent_config_parameters["encrypt_verify_outgoing"]}"
    server_key_file = "${var.blue_vault_consul_agent_config_parameters["ssl_path"]}/${var.blue_vault_config_parameters["consul_agent_key_name"]}"
    leave_on_terminate = "${var.blue_vault_consul_agent_config_parameters["leave_on_terminate"]}"
    log_level = "${var.blue_vault_consul_agent_config_parameters["log_level"]}"
    instance_short_name = "${var.instance_short_name["vault"]}"
    deployment_mode = "blue"
    environment = "${var.environment}"
    seq_number = "${count.index}"
    performance_leave_drain_Time = "${var.blue_vault_consul_agent_config_parameters["performance_leave_drain_Time"]}"
    performance_raft_multiplier = "${var.blue_vault_consul_agent_config_parameters["performance_raft_multiplier"]}"
    performance_rpc_hold_timeout = "${var.blue_vault_consul_agent_config_parameters["performance_rpc_hold_timeout"]}"
    ports_https = "${var.consul_https_port}"
    ports_http = "${var.blue_vault_consul_agent_config_parameters["ports_http"]}"
    reconnect_timeout = "${var.blue_vault_consul_agent_config_parameters["reconnect_timeout"]}"
    dns_server = "${jsonencode(data.terraform_remote_state.basic-infra.dns_server)}"
    retry_join_tag_key = "${var.blue_vault_consul_agent_config_parameters["retry_join_tag_key"]}"
    region = "${var.region}"
    retry_interval = "${var.blue_vault_consul_agent_config_parameters["retry_interval"]}"
    skip_leave_on_interrupt = "${var.blue_vault_consul_agent_config_parameters["skip_leave_on_interrupt"]}"
    telemetry_disable_hostname = "${var.blue_vault_consul_agent_config_parameters["telemetry_disable_hostname"]}"
    telemetry_filter_default = "${var.blue_vault_consul_agent_config_parameters["telemetry_filter_default"]}"
    telemetry_metrics_prefix = "${var.blue_vault_consul_agent_config_parameters["telemetry_metrics_prefix"]}"
    tls_min_version = "${var.blue_vault_consul_agent_config_parameters["tls_min_version"]}"
    tls_cipher_suites = "${var.blue_vault_consul_agent_config_parameters["tls_cipher_suites"]}"
    tls_prefer_server_cipher_suites = "${var.blue_vault_consul_agent_config_parameters["tls_prefer_server_cipher_suites"]}"
    ui = "${var.blue_vault_consul_agent_config_parameters["ui"]}"
    verify_incoming = "${var.blue_vault_consul_agent_config_parameters["verify_incoming"]}"
    verify_outgoing = "${var.blue_vault_consul_agent_config_parameters["verify_outgoing"]}"
    verify_incoming_rpc = "${var.blue_vault_consul_agent_config_parameters["verify_incoming_rpc"]}"
    verify_incoming_https = "${var.blue_vault_consul_agent_config_parameters["verify_incoming_https"]}"
    verify_server_hostname = "${var.blue_vault_consul_agent_config_parameters["verify_server_hostname"]}"
    consul_version = "${var.blue_vault_user_data_config["consul_version"]}"
    consul_license = "${var.blue_vault_user_data_config["consul_license"]}"
    consul_domain_name = "${var.consul_domain_name}"
    consul_acl_status = "${var.blue_vault_consul_agent_config_parameters["consul_acl_status"]}"
    acl_policy_ttl = "${var.blue_vault_consul_agent_config_parameters["acl_policy_ttl"]}"
    acl_token_ttl = "${var.blue_vault_consul_agent_config_parameters["acl_token_ttl"]}"
    agent_master_uuid = "${random_uuid.uuids.result}"
    grpc_port = "${var.grpc_port}"
  }
}

data "template_file" "green_consul_config" {
  count = "${var.is_green_mode_active == "yes" ? var.total_no_of_vault_servers["green"] : 0}"
  template = "${file("${var.green_vault_config_parameters["consul_config_template"]}")}"
  vars {
    dc_name = "${local.dc_name}"
    acl_default_policy = "${var.green_vault_consul_agent_config_parameters["acl_default_policy"]}"
    acl_down_policy = "${var.green_vault_consul_agent_config_parameters["acl_down_policy"]}"
    autopilot_cleanup_dead_servers = "${var.green_vault_consul_agent_config_parameters["autopilot_cleanup_dead_servers"]}"
    autopilot_last_contact_threshold = "${var.green_vault_consul_agent_config_parameters["autopilot_last_contact_threshold"]}"
    autopilot_max_trailing_logs = "${var.green_vault_consul_agent_config_parameters["autopilot_max_trailing_logs"]}"
    autopilot_server_stablization_time = "${var.green_vault_consul_agent_config_parameters["autopilot_server_stablization_time"]}"
    autopilot_disable_upgrade_migration = "${var.green_vault_consul_agent_config_parameters["autopilot_disable_upgrade_migration"]}"
    number_of_consul_servers = "${var.total_no_of_vault_servers["green"]}"
    ca_path = "${var.green_vault_consul_agent_config_parameters["ca_path"]}"
    server_cert_file = "${var.green_vault_consul_agent_config_parameters["ssl_path"]}/${var.green_vault_config_parameters["consul_agent_cert_name"]}"
    check_update_interval = "${var.green_vault_consul_agent_config_parameters["check_update_interval"]}"
    data_dir = "${var.green_vault_consul_agent_config_parameters["data_dir"]}"
    disable_anonymous_signature = "${var.green_vault_consul_agent_config_parameters["disable_anonymous_signature"]}"
    disable_http_unprintable_char_filter = "${var.green_vault_consul_agent_config_parameters["disable_http_unprintable_char_filter"]}"
    disable_remote_exec = "${var.green_vault_consul_agent_config_parameters["disable_remote_exec"]}"
    disable_update_check = "${var.green_vault_consul_agent_config_parameters["disable_update_check"]}"
    discard_check_output = "${var.green_vault_consul_agent_config_parameters["discard_check_output"]}"
    discovery_max_stale = "${var.green_vault_consul_agent_config_parameters["discovery_max_stale"]}"
    dns_config_allow_stale = "${var.green_vault_consul_agent_config_parameters["dns_config_allow_stale"]}"
    dns_config_max_stale = "${var.green_vault_consul_agent_config_parameters["dns_config_max_stale"]}"
    dns_config_node_ttl = "${var.green_vault_consul_agent_config_parameters["dns_config_node_ttl"]}"
    dns_config_enable_truncate = "${var.green_vault_consul_agent_config_parameters["dns_config_enable_truncate"]}"
    dns_config_only_passing = "${var.green_vault_consul_agent_config_parameters["dns_config_only_passing"]}"
    dns_config_recursor_timeout = "${var.green_vault_consul_agent_config_parameters["dns_config_recursor_timeout"]}"
    dns_config_disable_compression = "${var.green_vault_consul_agent_config_parameters["dns_config_disable_compression"]}"
    domain_name = "${var.dhcp_domain}"
    enable_acl_replication = "${var.green_vault_consul_agent_config_parameters["enable_acl_replication"]}"
    enable_agent_tls_for_checks = "${var.green_vault_consul_agent_config_parameters["enable_agent_tls_for_checks"]}"
    enable_debug = "${var.green_vault_consul_agent_config_parameters["enable_debug"]}"
    enable_syslog = "${var.green_vault_consul_agent_config_parameters["enable_syslog"]}"
    encrypt_verify_incoming = "${var.green_vault_consul_agent_config_parameters["encrypt_verify_incoming"]}"
    encrypt_verify_outgoing = "${var.green_vault_consul_agent_config_parameters["encrypt_verify_outgoing"]}"
    server_key_file = "${var.green_vault_consul_agent_config_parameters["ssl_path"]}/${var.green_vault_config_parameters["consul_agent_key_name"]}"
    leave_on_terminate = "${var.green_vault_consul_agent_config_parameters["leave_on_terminate"]}"
    log_level = "${var.green_vault_consul_agent_config_parameters["log_level"]}"
    instance_short_name = "${var.instance_short_name["vault"]}"
    deployment_mode = "green"
    environment = "${var.environment}"
    seq_number = "${count.index}"
    performance_leave_drain_Time = "${var.green_vault_consul_agent_config_parameters["performance_leave_drain_Time"]}"
    performance_raft_multiplier = "${var.green_vault_consul_agent_config_parameters["performance_raft_multiplier"]}"
    performance_rpc_hold_timeout = "${var.green_vault_consul_agent_config_parameters["performance_rpc_hold_timeout"]}"
    ports_https = "${var.consul_https_port}"
    ports_http = "${var.green_vault_consul_agent_config_parameters["ports_http"]}"
    reconnect_timeout = "${var.green_vault_consul_agent_config_parameters["reconnect_timeout"]}"
    dns_server = "${jsonencode(data.terraform_remote_state.basic-infra.dns_server)}"
    retry_join_tag_key = "${var.green_vault_consul_agent_config_parameters["retry_join_tag_key"]}"
    region = "${var.region}"
    retry_interval = "${var.green_vault_consul_agent_config_parameters["retry_interval"]}"
    skip_leave_on_interrupt = "${var.green_vault_consul_agent_config_parameters["skip_leave_on_interrupt"]}"
    telemetry_disable_hostname = "${var.green_vault_consul_agent_config_parameters["telemetry_disable_hostname"]}"
    telemetry_filter_default = "${var.green_vault_consul_agent_config_parameters["telemetry_filter_default"]}"
    telemetry_metrics_prefix = "${var.green_vault_consul_agent_config_parameters["telemetry_metrics_prefix"]}"
    tls_min_version = "${var.green_vault_consul_agent_config_parameters["tls_min_version"]}"
    tls_cipher_suites = "${var.green_vault_consul_agent_config_parameters["tls_cipher_suites"]}"
    tls_prefer_server_cipher_suites = "${var.green_vault_consul_agent_config_parameters["tls_prefer_server_cipher_suites"]}"
    ui = "${var.green_vault_consul_agent_config_parameters["ui"]}"
    verify_incoming = "${var.green_vault_consul_agent_config_parameters["verify_incoming"]}"
    verify_outgoing = "${var.green_vault_consul_agent_config_parameters["verify_outgoing"]}"
    verify_incoming_rpc = "${var.green_vault_consul_agent_config_parameters["verify_incoming_rpc"]}"
    verify_incoming_https = "${var.green_vault_consul_agent_config_parameters["verify_incoming_https"]}"
    verify_server_hostname = "${var.green_vault_consul_agent_config_parameters["verify_server_hostname"]}"
    consul_version = "${var.green_vault_user_data_config["consul_version"]}"
    consul_license = "${var.green_vault_user_data_config["consul_license"]}"
    consul_domain_name = "${var.consul_domain_name}"
    consul_acl_status = "${var.green_vault_consul_agent_config_parameters["consul_acl_status"]}"
    acl_policy_ttl = "${var.green_vault_consul_agent_config_parameters["acl_policy_ttl"]}"
    acl_token_ttl = "${var.green_vault_consul_agent_config_parameters["acl_token_ttl"]}"
    agent_master_uuid = "${random_uuid.uuids.result}"
    grpc_port = "${var.grpc_port}"
  }
}

#-------------------------------------------------------------
### Template the Vault config
#-------------------------------------------------------------
data "template_file" "blue_vault_config" {
  count = "${var.is_blue_mode_active == "yes" ? var.total_no_of_vault_servers["blue"] : 0}"
  template = "${file("${var.blue_vault_config_parameters["vault_config_template"]}")}"
  vars {
    ui = "${var.blue_vault_config_parameters["ui"]}"
    consul_https_port = "${var.consul_https_port}"
    vault_cluster_name = "${local.dc_name}"
    cache_size = "${var.blue_vault_config_parameters["cache_size"]}"
    disable_cache = "${var.blue_vault_config_parameters["disable_cache"]}"
    vault_log_level = "${var.blue_vault_config_parameters["log_level"]}"
    node_name = "blue-${var.environment}-${var.instance_short_name["vault"]}"
    seq_number = "${count.index}"
    domain_name = "${var.dhcp_domain}"
    vault_port = "${var.vault_port}"
    vault_cluster_port = "${var.vault_cluster_port}"
    disable_clustering = "${var.blue_vault_config_parameters["disable_clustering"]}"
    consul_agent_check_timeout = "${var.blue_vault_config_parameters["consul_agent_check_timeout"]}"
    consul_agent_consistency_mode = "${var.blue_vault_config_parameters["consul_agent_consistency_mode"]}"
    consul_agent_disable_registration = "${var.blue_vault_config_parameters["consul_agent_disable_registration"]}"
    consul_agent_max_parallel = "${var.blue_vault_config_parameters["consul_agent_max_parallel"]}"
    vault_path_in_consul = "${var.blue_vault_config_parameters["vault_path_in_consul"]}"
    consul_agent_connection_method = "${var.blue_vault_config_parameters["consul_agent_connection_method"]}"
    vault_service_name_in_consul = "${var.blue_vault_config_parameters["vault_service_name_in_consul"]}"
    vault_service_tags_in_consul = "${var.blue_vault_config_parameters["vault_service_tags_in_consul"]}"
    vault_service_addrs_in_consul = "${var.blue_vault_config_parameters["vault_service_addrs_in_consul"]}"
    consul_agent_session_ttl = "${var.blue_vault_config_parameters["consul_agent_session_ttl"]}"
    consul_agent_lock_wait_time = "${var.blue_vault_config_parameters["consul_agent_lock_wait_time"]}"
    ca_file = "${var.blue_vault_config_parameters["ca_file"]}"
    consul_client_cert_file = "${var.blue_vault_config_parameters["ssl_path"]}/${var.blue_vault_config_parameters["consul_client_cert_name"]}"
    consul_client_key_file = "${var.blue_vault_config_parameters["ssl_path"]}/${var.blue_vault_config_parameters["consul_client_cert_key"]}"
    tls_min_version = "${var.blue_vault_config_parameters["tls_min_version"]}"
    consul_agent_tls_skip_verify = "${var.blue_vault_config_parameters["consul_agent_tls_skip_verify"]}"
    max_request_size = "${var.blue_vault_config_parameters["max_request_size"]}"
    proxy_protocol_behaviour = "${var.blue_vault_config_parameters["proxy_protocol_behaviour"]}"
    proxy_protocol_authorized_addrs = "${var.blue_vault_config_parameters["proxy_protocol_authorized_addrs"]}"
    tls_disable = "${var.blue_vault_config_parameters["tls_disable"]}"
    server_cert_file = "${var.blue_vault_config_parameters["ssl_path"]}/${var.blue_vault_config_parameters["vault_server_cert_name"]}"
    server_key_file = "${var.blue_vault_config_parameters["ssl_path"]}/${var.blue_vault_config_parameters["vault_server_cert_key"]}"
    tls_cipher_suites = "${var.blue_vault_config_parameters["tls_cipher_suites"]}"
    tls_prefer_server_cipher_suites = "${var.blue_vault_config_parameters["tls_prefer_server_cipher_suites"]}"
    tls_require_and_verify_client_cert = "${var.blue_vault_config_parameters["tls_require_and_verify_client_cert"]}"
    tls_disable_client_certs = "${var.blue_vault_config_parameters["tls_disable_client_certs"]}"
    telemetry_disable_hostname = "${var.blue_vault_config_parameters["telemetry_disable_hostname"]}"
    vault_plugin_directory = "${var.blue_vault_config_parameters["plugin_directory"]}"
    region = "${var.region}"
    kms_key_id = "${element(module.unseal_kms_key.kms_key_id,0)}"
  }
}

data "template_file" "green_vault_config" {
  count = "${var.is_green_mode_active == "yes" ? var.total_no_of_vault_servers["green"] : 0}"
  template = "${file("${var.green_vault_config_parameters["vault_config_template"]}")}"
  vars {
    ui = "${var.green_vault_config_parameters["ui"]}"
    consul_https_port = "${var.consul_https_port}"
    vault_cluster_name = "${local.dc_name}"
    cache_size = "${var.green_vault_config_parameters["cache_size"]}"
    disable_cache = "${var.green_vault_config_parameters["disable_cache"]}"
    vault_log_level = "${var.green_vault_config_parameters["log_level"]}"
    node_name = "green-${var.environment}-${var.instance_short_name["vault"]}"
    seq_number = "${count.index}"
    domain_name = "${var.dhcp_domain}"
    vault_port = "${var.vault_port}"
    vault_cluster_port = "${var.vault_cluster_port}"
    disable_clustering = "${var.green_vault_config_parameters["disable_clustering"]}"
    consul_agent_check_timeout = "${var.green_vault_config_parameters["consul_agent_check_timeout"]}"
    consul_agent_consistency_mode = "${var.green_vault_config_parameters["consul_agent_consistency_mode"]}"
    consul_agent_disable_registration = "${var.green_vault_config_parameters["consul_agent_disable_registration"]}"
    consul_agent_max_parallel = "${var.green_vault_config_parameters["consul_agent_max_parallel"]}"
    vault_path_in_consul = "${var.green_vault_config_parameters["vault_path_in_consul"]}"
    consul_agent_connection_method = "${var.green_vault_config_parameters["consul_agent_connection_method"]}"
    vault_service_name_in_consul = "${var.green_vault_config_parameters["vault_service_name_in_consul"]}"
    vault_service_tags_in_consul = "${var.green_vault_config_parameters["vault_service_tags_in_consul"]}"
    vault_service_addrs_in_consul = "${var.green_vault_config_parameters["vault_service_addrs_in_consul"]}"
    consul_agent_session_ttl = "${var.green_vault_config_parameters["consul_agent_session_ttl"]}"
    consul_agent_lock_wait_time = "${var.green_vault_config_parameters["consul_agent_lock_wait_time"]}"
    ca_file = "${var.green_vault_config_parameters["ca_file"]}"
    consul_client_cert_file = "${var.green_vault_config_parameters["ssl_path"]}/${var.green_vault_config_parameters["consul_client_cert_name"]}"
    consul_client_key_file = "${var.green_vault_config_parameters["ssl_path"]}/${var.green_vault_config_parameters["consul_client_cert_key"]}"
    tls_min_version = "${var.green_vault_config_parameters["tls_min_version"]}"
    consul_agent_tls_skip_verify = "${var.green_vault_config_parameters["consul_agent_tls_skip_verify"]}"
    max_request_size = "${var.green_vault_config_parameters["max_request_size"]}"
    proxy_protocol_behaviour = "${var.green_vault_config_parameters["proxy_protocol_behaviour"]}"
    proxy_protocol_authorized_addrs = "${var.green_vault_config_parameters["proxy_protocol_authorized_addrs"]}"
    tls_disable = "${var.green_vault_config_parameters["tls_disable"]}"
    server_cert_file = "${var.green_vault_config_parameters["ssl_path"]}/${var.green_vault_config_parameters["vault_server_cert_name"]}"
    server_key_file = "${var.green_vault_config_parameters["ssl_path"]}/${var.green_vault_config_parameters["vault_server_cert_key"]}"
    tls_cipher_suites = "${var.green_vault_config_parameters["tls_cipher_suites"]}"
    tls_prefer_server_cipher_suites = "${var.green_vault_config_parameters["tls_prefer_server_cipher_suites"]}"
    tls_require_and_verify_client_cert = "${var.green_vault_config_parameters["tls_require_and_verify_client_cert"]}"
    tls_disable_client_certs = "${var.green_vault_config_parameters["tls_disable_client_certs"]}"
    telemetry_disable_hostname = "${var.green_vault_config_parameters["telemetry_disable_hostname"]}"
    vault_plugin_directory = "${var.green_vault_config_parameters["plugin_directory"]}"
    region = "${var.region}"
    kms_key_id = "${element(module.unseal_kms_key.kms_key_id,0)}"
  }
}

#-------------------------------------------------------------
### Template the Vault Policies
#-------------------------------------------------------------
data "template_file" "blue_vault_policies" {
  count = "${length(var.blue_vault_policies)}"
  template = "${file(format("%s%s%s%s",var.blue_vault_policy_dir,"/",var.blue_vault_policies[count.index],".hcl"))}"
}

data "template_file" "green_vault_policies" {
  count = "${length(var.green_vault_policies)}"
  template = "${file(format("%s%s%s%s",var.green_vault_policy_dir,"/",var.green_vault_policies[count.index],".hcl"))}"
}

#-------------------------------------------------------------
### Template the user data files
#-------------------------------------------------------------
data "template_file" "blue-user-data-script" {
  count = "${var.is_blue_mode_active == "yes" ? local.len_blue_user_data * local.len_blue_servers : 0}"
  template =  "${file(var.blue_vault_user_data_scripts[count.index >= local.len_blue_user_data ? (count.index - local.len_blue_user_data) % local.len_blue_user_data : count.index % local.len_blue_user_data])}"
  vars {
      node_name = "blue-${var.environment}-${var.instance_short_name["vault"]}"
      seq_number = "${count.index / local.len_blue_user_data}"
      consul_group_id = "${var.group_id["consul"]}"
      consul_user_id = "${var.user_id["consul"]}"
      vault_group_id = "${var.group_id["vault"]}"
      vault_user_id = "${var.user_id["vault"]}"
      consul_user_name = "${var.user_name["consul"]}"
      vault_user_name = "${var.user_name["vault"]}"
      consul_group_name = "${var.group_name["consul"]}"
      vault_group_name = "${var.group_name["vault"]}"
      vault_volume_names = "${jsonencode(module.blue-vault-servers.ebs_volume_maps)}"
      no_of_volumes_per_vg = "${jsonencode(var.blue_vault_vg_config["no_of_volumes_per_vg"])}"
      vg_names = "${jsonencode(var.blue_vault_vg_config["vg_names"])}"
      lv_names = "${jsonencode(var.blue_vault_vg_config["lv_names"])}"
      no_of_lvs_per_vg = "${jsonencode(var.blue_vault_vg_config["no_of_lvs_per_vg"])}"
      lv_frees = "${jsonencode(var.blue_vault_vg_config["lv_frees"])}"
      mount_points = "${jsonencode(var.blue_vault_vg_config["mount_points"])}"
      consul_data_path = "${var.blue_vault_consul_agent_config_parameters["data_dir"]}"
      consul_config_path = "${var.blue_vault_consul_agent_config_parameters["config_path"]}"
      consul_ssl_path = "${var.blue_vault_consul_agent_config_parameters["ssl_path"]}"
      vault_log_path = "${var.blue_vault_config_parameters["log_path"]}"
      vault_config_path = "${var.blue_vault_config_parameters["config_path"]}"
      vault_ssl_path = "${var.blue_vault_config_parameters["ssl_path"]}"
      vault_data_path = "${var.blue_vault_config_parameters["data_path"]}"
      vault_plugin_path = "${var.blue_vault_config_parameters["plugin_directory"]}"
      ca_path = "${var.blue_vault_consul_agent_config_parameters["ca_path"]}"
      consul_client_cert_name = "${var.blue_vault_config_parameters["consul_client_cert_name"]}"
      consul_client_key_name = "${var.blue_vault_config_parameters["consul_client_cert_key"]}"
      domain_name = "${var.dhcp_domain}"
      region = "${var.region}"
      deployment_mode = "blue"
      project = "${var.project}"
      environment = "${var.environment}"
      consul_config_name = "${var.blue_vault_config_parameters["consul_config_name"]}"
      vault_config_name = "${var.blue_vault_config_parameters["vault_config_name"]}"
      consul_config = "${data.template_file.blue_consul_config.*.rendered[count.index / local.len_blue_user_data]}"
      vault_config = "${data.template_file.blue_vault_config.*.rendered[count.index / local.len_blue_user_data]}"
      vault_server_cert_name = "${var.blue_vault_config_parameters["vault_server_cert_name"]}"
      #vault_server_cert = "${file("certs/blue-vault-server-${count.index / local.len_blue_user_data}.crt")}"
      vault_server_key_name = "${var.blue_vault_config_parameters["vault_server_cert_key"]}"
      #vault_server_key = "${module.blue_vault_server_cert_key.private_key_pem[count.index / local.len_blue_user_data]}"
      consul_client_cert_name = "${var.blue_vault_config_parameters["consul_client_cert_name"]}"
      #consul_client_cert = "${file("certs/blue-vault-consul-client-${count.index / local.len_blue_user_data}.crt")}"
      consul_client_key_name = "${var.blue_vault_config_parameters["consul_client_cert_key"]}"
      #consul_client_key = "${module.blue_consul_client_cert_key.private_key_pem[count.index / local.len_blue_user_data]}"
      consul_agent_cert_name = "${var.blue_vault_config_parameters["consul_agent_cert_name"]}"
      #consul_agent_cert = "${file("certs/blue-vault-consul-agent-${count.index / local.len_blue_user_data}.crt")}"
      consul_agent_key_name = "${var.blue_vault_config_parameters["consul_agent_key_name"]}"
      #consul_agent_key = "${module.blue_consul_agent_cert_key.private_key_pem[count.index / local.len_blue_user_data]}"
      master_uuid = "${element(data.terraform_remote_state.consul.uuids,0)}"
      consul_server_name = "${element(data.terraform_remote_state.consul.blue_common_dns_fqdn,0)}"
      consul_https_port = "${var.consul_https_port}"
      ca_file = "${var.blue_vault_config_parameters["ca_file"]}"
      vault_port = "${var.vault_port}"
      secret_threshold = "${var.blue_vault_config_parameters["secret_threshold"]}"
      vault_license = "${var.blue_vault_user_data_config["vault_license"]}"
      vault_audit_log_file_path = "${var.blue_vault_user_data_config["vault_audit_log_file_path"]}"
      vault_license_number = "${var.blue_vault_config_parameters["vault_license_number"]}"
      vault_auth_ldap_name = "${var.blue_vault_config_parameters["vault_auth_ldap_name"]}"
      vault_ldap_default_ttl = "${var.blue_vault_config_parameters["vault_ldap_default_ttl"]}"
      vault_ldap_max_ttl = "${var.blue_vault_config_parameters["vault_ldap_max_ttl"]}"
      vault_ldap_name = "${var.blue_vault_config_parameters["vault_ldap_name"]}"
      vault_ldap_starttls = "${var.blue_vault_config_parameters["vault_ldap_starttls"]}"
      vault_ldap_binddn = "uid=svc-${local.dc_name},${var.blue_vault_config_parameters["vault_ldap_userdn"]}"
      vault_ldap_bindpassword = "${var.blue_vault_config_parameters["vault_ldap_bindpassword"]}"
      vault_ldap_userdn = "${var.blue_vault_config_parameters["vault_ldap_userdn"]}"
      vault_ldap_groupdn = "${var.blue_vault_config_parameters["vault_ldap_groupdn"]}"
      vault_ldap_userattr = "${var.blue_vault_config_parameters["vault_ldap_userattr"]}"
      default_ldap_group_maps = "${jsonencode(var.blue_default_ldap_group_maps)}"
      policy_names = "${jsonencode(var.blue_vault_policies)}"
      token_role_maps = "${jsonencode(var.blue_token_role_maps)}"
      disallowed_policies_in_token_role = "${var.blue_vault_disallowed_policies_in_token_role}"
      token_role_orphan_status = "${var.blue_vault_config_parameters["token_role_orphan_status"]}"
      token_role_renewable_status = "${var.blue_vault_config_parameters["token_role_renewable_status"]}"
      dc_name = "${local.dc_name}"
      consul_agent_connection_method = "${var.blue_vault_config_parameters["consul_agent_connection_method"]}"
      backup_bucket_name = "${element(data.terraform_remote_state.consul.backup_bucket_name,0)}"
      new_project_policies = "${var.blue_new_project_policies}"
      delete_project_policies = "${var.blue_delete_project_policies}"’’
  }
}

data "template_file" "green-user-data-script" {
  count = "${var.is_green_mode_active == "yes" ? local.len_green_user_data * local.len_green_servers : 0}"
  template =  "${file(var.green_vault_user_data_scripts[count.index >= local.len_green_user_data ? (count.index - local.len_green_user_data) % local.len_green_user_data : count.index % local.len_green_user_data])}"
  vars {
      node_name = "green-${var.environment}-${var.instance_short_name["vault"]}"
      seq_number = "${count.index / local.len_green_user_data}"
      consul_group_id = "${var.group_id["consul"]}"
      consul_user_id = "${var.user_id["consul"]}"
      vault_group_id = "${var.group_id["vault"]}"
      vault_user_id = "${var.user_id["vault"]}"
      consul_user_name = "${var.user_name["consul"]}"
      vault_user_name = "${var.user_name["vault"]}"
      consul_group_name = "${var.group_name["consul"]}"
      vault_group_name = "${var.group_name["vault"]}"
      vault_volume_names = "${jsonencode(module.green-vault-servers.ebs_volume_maps)}"
      no_of_volumes_per_vg = "${jsonencode(var.green_vault_vg_config["no_of_volumes_per_vg"])}"
      vg_names = "${jsonencode(var.green_vault_vg_config["vg_names"])}"
      lv_names = "${jsonencode(var.green_vault_vg_config["lv_names"])}"
      no_of_lvs_per_vg = "${jsonencode(var.green_vault_vg_config["no_of_lvs_per_vg"])}"
      lv_frees = "${jsonencode(var.green_vault_vg_config["lv_frees"])}"
      mount_points = "${jsonencode(var.green_vault_vg_config["mount_points"])}"
      consul_data_path = "${var.green_vault_consul_agent_config_parameters["data_dir"]}"
      consul_config_path = "${var.green_vault_consul_agent_config_parameters["config_path"]}"
      consul_ssl_path = "${var.green_vault_consul_agent_config_parameters["ssl_path"]}"
      vault_log_path = "${var.green_vault_config_parameters["log_path"]}"
      vault_config_path = "${var.green_vault_config_parameters["config_path"]}"
      vault_ssl_path = "${var.green_vault_config_parameters["ssl_path"]}"
      vault_data_path = "${var.green_vault_config_parameters["data_path"]}"
      vault_plugin_path = "${var.green_vault_config_parameters["plugin_directory"]}"
      ca_path = "${var.green_vault_consul_agent_config_parameters["ca_path"]}"
      consul_client_cert_name = "${var.green_vault_config_parameters["consul_client_cert_name"]}"
      consul_client_key_name = "${var.green_vault_config_parameters["consul_client_cert_key"]}"
      domain_name = "${var.dhcp_domain}"
      region = "${var.region}"
      deployment_mode = "green"
      project = "${var.project}"
      environment = "${var.environment}"
      consul_config_name = "${var.green_vault_config_parameters["consul_config_name"]}"
      vault_config_name = "${var.green_vault_config_parameters["vault_config_name"]}"
      consul_config = "${data.template_file.green_consul_config.*.rendered[count.index / local.len_green_user_data]}"
      vault_config = "${data.template_file.green_vault_config.*.rendered[count.index / local.len_green_user_data]}"
      vault_server_cert_name = "${var.green_vault_config_parameters["vault_server_cert_name"]}"
      #vault_server_cert = "${file("certs/green-vault-server-${count.index / local.len_green_user_data}.crt")}"
      vault_server_key_name = "${var.green_vault_config_parameters["vault_server_cert_key"]}"
      #vault_server_key = "${module.green_vault_server_cert_key.private_key_pem[count.index / local.len_green_user_data]}"
      consul_client_cert_name = "${var.green_vault_config_parameters["consul_client_cert_name"]}"
      #consul_client_cert = "${file("certs/green-vault-consul-client-${count.index / local.len_green_user_data}.crt")}"
      consul_client_key_name = "${var.green_vault_config_parameters["consul_client_cert_key"]}"
      #consul_client_key = "${module.green_consul_client_cert_key.private_key_pem[count.index / local.len_green_user_data]}"
      consul_agent_cert_name = "${var.green_vault_config_parameters["consul_agent_cert_name"]}"
      #consul_agent_cert = "${file("certs/green-vault-consul-agent-${count.index / local.len_green_user_data}.crt")}"
      consul_agent_key_name = "${var.green_vault_config_parameters["consul_agent_key_name"]}"
      #consul_agent_key = "${module.green_consul_agent_cert_key.private_key_pem[count.index / local.len_green_user_data]}"
      master_uuid = "${element(data.terraform_remote_state.consul.uuids,0)}"
      consul_server_name = "${element(data.terraform_remote_state.consul.green_common_dns_fqdn,0)}"
      consul_https_port = "${var.consul_https_port}"
      ca_file = "${var.green_vault_config_parameters["ca_file"]}"
      vault_port = "${var.vault_port}"
      secret_threshold = "${var.green_vault_config_parameters["secret_threshold"]}"
      vault_license = "${var.green_vault_user_data_config["vault_license"]}"
      vault_audit_log_file_path = "${var.green_vault_user_data_config["vault_audit_log_file_path"]}"
      vault_license_number = "${var.green_vault_config_parameters["vault_license_number"]}"
      vault_auth_ldap_name = "${var.green_vault_config_parameters["vault_auth_ldap_name"]}"
      vault_ldap_default_ttl = "${var.green_vault_config_parameters["vault_ldap_default_ttl"]}"
      vault_ldap_max_ttl = "${var.green_vault_config_parameters["vault_ldap_max_ttl"]}"
      vault_ldap_name = "${var.green_vault_config_parameters["vault_ldap_name"]}"
      vault_ldap_starttls = "${var.green_vault_config_parameters["vault_ldap_starttls"]}"
      vault_ldap_binddn = "uid=svc-${local.dc_name},${var.blue_vault_config_parameters["vault_ldap_userdn"]}"
      vault_ldap_bindpassword = "${var.green_vault_config_parameters["vault_ldap_bindpassword"]}"
      vault_ldap_userdn = "${var.green_vault_config_parameters["vault_ldap_userdn"]}"
      vault_ldap_groupdn = "${var.green_vault_config_parameters["vault_ldap_groupdn"]}"
      vault_ldap_userattr = "${var.green_vault_config_parameters["vault_ldap_userattr"]}"
      default_ldap_group_maps = "${jsonencode(var.green_default_ldap_group_maps)}"
      policy_names = "${jsonencode(var.green_vault_policies)}"
      token_role_maps = "${jsonencode(var.green_token_role_maps)}"
      disallowed_policies_in_token_role = "${var.green_vault_disallowed_policies_in_token_role}"
      token_role_orphan_status = "${var.green_vault_config_parameters["token_role_orphan_status"]}"
      token_role_renewable_status = "${var.green_vault_config_parameters["token_role_renewable_status"]}"
      dc_name = "${local.dc_name}"
      consul_agent_connection_method = "${var.green_vault_config_parameters["consul_agent_connection_method"]}"
      backup_bucket_name = "${element(data.terraform_remote_state.consul.backup_bucket_name,0)}"
      new_project_policies = "${var.green_new_project_policies}"
      delete_project_policies = "${var.green_delete_project_policies}"
  }
}

# Unforutnately, this has to be increased if the number of user data script changes

data "template_cloudinit_config" "blue-user-data-file" {
  count = "${var.is_blue_mode_active == "yes" ? var.total_no_of_vault_servers["blue"] : 0}"
  gzip          = true
  base64_encode = true
  part {
      content_type = "text/x-shellscript"
      content = "${data.template_file.blue-user-data-script.*.rendered[(count.index + local.len_blue_user_data) > local.len_blue_user_data ? (count.index * local.len_blue_user_data) : count.index ]}"
  }
  part {
      content_type = "text/x-shellscript"
      content = "${data.template_file.blue-user-data-script.*.rendered[(count.index + local.len_blue_user_data) > local.len_blue_user_data ? (count.index * local.len_blue_user_data) + 1 : count.index + 1]}"
  }
  part {
      content_type = "text/x-shellscript"
      content = "${data.template_file.blue-user-data-script.*.rendered[(count.index + local.len_blue_user_data) > local.len_blue_user_data ? (count.index * local.len_blue_user_data) + 2 : count.index + 2]}"
  }
  part {
      content_type = "text/x-shellscript"
      content = "${data.template_file.blue-user-data-script.*.rendered[(count.index + local.len_blue_user_data) > local.len_blue_user_data ? (count.index * local.len_blue_user_data) + 3 : count.index + 3]}"
  }
  part {
      content_type = "text/x-shellscript"
      content = "${data.template_file.blue-user-data-script.*.rendered[(count.index + local.len_blue_user_data) > local.len_blue_user_data ? (count.index * local.len_blue_user_data) + 4 : count.index + 4]}"
  }
  part {
      content_type = "text/x-shellscript"
      content = "${data.template_file.blue-user-data-script.*.rendered[(count.index + local.len_blue_user_data) > local.len_blue_user_data ? (count.index * local.len_blue_user_data) + 5 : count.index + 5]}"
  }
}

data "template_cloudinit_config" "green-user-data-file" {
  count = "${var.is_green_mode_active == "yes" ? var.total_no_of_vault_servers["green"] : 0}"
  gzip          = true
  base64_encode = true
  part {
      content_type = "text/x-shellscript"
      content = "${data.template_file.green-user-data-script.*.rendered[(count.index + local.len_green_user_data) > local.len_green_user_data ? (count.index * local.len_green_user_data) : count.index ]}"
  }
  part {
      content_type = "text/x-shellscript"
      content = "${data.template_file.green-user-data-script.*.rendered[(count.index + local.len_green_user_data) > local.len_green_user_data ? (count.index * local.len_green_user_data) + 1 : count.index + 1]}"
  }
  part {
      content_type = "text/x-shellscript"
      content = "${data.template_file.green-user-data-script.*.rendered[(count.index + local.len_green_user_data) > local.len_green_user_data ? (count.index * local.len_green_user_data) + 2 : count.index + 2]}"
  }
  part {
      content_type = "text/x-shellscript"
      content = "${data.template_file.green-user-data-script.*.rendered[(count.index + local.len_green_user_data) > local.len_green_user_data ? (count.index * local.len_green_user_data) + 3 : count.index + 3]}"
  }
  part {
      content_type = "text/x-shellscript"
      content = "${data.template_file.green-user-data-script.*.rendered[(count.index + local.len_green_user_data) > local.len_green_user_data ? (count.index * local.len_green_user_data) + 4 : count.index + 4]}"
  }
  part {
      content_type = "text/x-shellscript"
      content = "${data.template_file.green-user-data-script.*.rendered[(count.index + local.len_green_user_data) > local.len_green_user_data ? (count.index * local.len_green_user_data) + 5 : count.index + 5]}"
  }
}
