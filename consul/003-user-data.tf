####################################################
# Generate UUIDs
####################################################
resource "random_uuid" "uuids" {
  count = "${var.no_of_uuids_to_generate}"
}

####################################################
# Create S3 Bucket for Consul Backup
####################################################
module "backup_bucket" {
  source = "./s3bucket"
  project = "${var.project}"
  environment = "${var.environment}"
  region = "${var.region}"
  s3_bucket_name = ["${local.dc_name}-backup"]
}

#-------------------------------------------------------------
### Template the Consul Config File
#-------------------------------------------------------------
data "template_file" "blue_consul_config" {
  count = "${var.is_blue_mode_active == "yes" ? var.total_no_of_consul_servers["blue"] : 0}"
  template = "${file("${var.blue_consul_config_parameters["config_template"]}")}"
  vars {
    dc_name = "${local.dc_name}"
    acl_default_policy = "${var.blue_consul_config_parameters["acl_default_policy"]}"
    acl_down_policy = "${var.blue_consul_config_parameters["acl_down_policy"]}"
    autopilot_cleanup_dead_servers = "${var.blue_consul_config_parameters["autopilot_cleanup_dead_servers"]}"
    autopilot_last_contact_threshold = "${var.blue_consul_config_parameters["autopilot_last_contact_threshold"]}"
    autopilot_max_trailing_logs = "${var.blue_consul_config_parameters["autopilot_max_trailing_logs"]}"
    autopilot_server_stablization_time = "${var.blue_consul_config_parameters["autopilot_server_stablization_time"]}"
    autopilot_disable_upgrade_migration = "${var.blue_consul_config_parameters["autopilot_disable_upgrade_migration"]}"
    number_of_consul_servers = "${var.total_no_of_consul_servers["blue"]}"
    ca_path = "${var.blue_consul_config_parameters["ca_path"]}"
    server_cert_file = "${var.blue_consul_config_parameters["ssl_path"]}/${var.blue_consul_config_parameters["server_cert_name"]}"
    check_update_interval = "${var.blue_consul_config_parameters["check_update_interval"]}"
    data_dir = "${var.blue_consul_config_parameters["data_dir"]}"
    disable_anonymous_signature = "${var.blue_consul_config_parameters["disable_anonymous_signature"]}"
    disable_http_unprintable_char_filter = "${var.blue_consul_config_parameters["disable_http_unprintable_char_filter"]}"
    disable_remote_exec = "${var.blue_consul_config_parameters["disable_remote_exec"]}"
    disable_update_check = "${var.blue_consul_config_parameters["disable_update_check"]}"
    discard_check_output = "${var.blue_consul_config_parameters["discard_check_output"]}"
    discovery_max_stale = "${var.blue_consul_config_parameters["discovery_max_stale"]}"
    dns_config_allow_stale = "${var.blue_consul_config_parameters["dns_config_allow_stale"]}"
    dns_config_max_stale = "${var.blue_consul_config_parameters["dns_config_max_stale"]}"
    dns_config_node_ttl = "${var.blue_consul_config_parameters["dns_config_node_ttl"]}"
    dns_config_enable_truncate = "${var.blue_consul_config_parameters["dns_config_enable_truncate"]}"
    dns_config_only_passing = "${var.blue_consul_config_parameters["dns_config_only_passing"]}"
    dns_config_recursor_timeout = "${var.blue_consul_config_parameters["dns_config_recursor_timeout"]}"
    dns_config_disable_compression = "${var.blue_consul_config_parameters["dns_config_disable_compression"]}"
    domain_name = "${var.dhcp_domain}"
    enable_acl_replication = "${var.blue_consul_config_parameters["enable_acl_replication"]}"
    enable_agent_tls_for_checks = "${var.blue_consul_config_parameters["enable_agent_tls_for_checks"]}"
    enable_debug = "${var.blue_consul_config_parameters["enable_debug"]}"
    enable_syslog = "${var.blue_consul_config_parameters["enable_syslog"]}"
    encrypt_verify_incoming = "${var.blue_consul_config_parameters["encrypt_verify_incoming"]}"
    encrypt_verify_outgoing = "${var.blue_consul_config_parameters["encrypt_verify_outgoing"]}"
    server_key_file = "${var.blue_consul_config_parameters["ssl_path"]}/${var.blue_consul_config_parameters["server_cert_key"]}"
    leave_on_terminate = "${var.blue_consul_config_parameters["leave_on_terminate"]}"
    log_level = "${var.blue_consul_config_parameters["log_level"]}"
    instance_short_name = "${var.instance_short_name["consul"]}"
    deployment_mode = "blue"
    environment = "${var.environment}"
    seq_number = "${count.index}"
    performance_leave_drain_Time = "${var.blue_consul_config_parameters["performance_leave_drain_Time"]}"
    performance_raft_multiplier = "${var.blue_consul_config_parameters["performance_raft_multiplier"]}"
    performance_rpc_hold_timeout = "${var.blue_consul_config_parameters["performance_rpc_hold_timeout"]}"
    ports_https = "${var.consul_https_port}"
    ports_http = "${var.blue_consul_config_parameters["ports_http"]}"
    reconnect_timeout = "${var.blue_consul_config_parameters["reconnect_timeout"]}"
    dns_server = "${jsonencode(data.terraform_remote_state.basic-infra.dns_server)}"
    retry_join_tag_key = "${var.blue_consul_config_parameters["retry_join_tag_key"]}"
    region = "${var.region}"
    retry_interval = "${var.blue_consul_config_parameters["retry_interval"]}"
    skip_leave_on_interrupt = "${var.blue_consul_config_parameters["skip_leave_on_interrupt"]}"
    telemetry_disable_hostname = "${var.blue_consul_config_parameters["telemetry_disable_hostname"]}"
    telemetry_filter_default = "${var.blue_consul_config_parameters["telemetry_filter_default"]}"
    telemetry_metrics_prefix = "${var.blue_consul_config_parameters["telemetry_metrics_prefix"]}"
    tls_min_version = "${var.blue_consul_config_parameters["tls_min_version"]}"
    tls_cipher_suites = "${var.blue_consul_config_parameters["tls_cipher_suites"]}"
    tls_prefer_server_cipher_suites = "${var.blue_consul_config_parameters["tls_prefer_server_cipher_suites"]}"
    ui = "${var.blue_consul_config_parameters["ui"]}"
    verify_incoming = "${var.blue_consul_config_parameters["verify_incoming"]}"
    verify_outgoing = "${var.blue_consul_config_parameters["verify_outgoing"]}"
    verify_incoming_rpc = "${var.blue_consul_config_parameters["verify_incoming_rpc"]}"
    verify_incoming_https = "${var.blue_consul_config_parameters["verify_incoming_https"]}"
    verify_server_hostname = "${var.blue_consul_config_parameters["verify_server_hostname"]}"
    consul_version = "${var.blue_consul_user_data_config["version"]}"
    consul_license = "${var.blue_consul_user_data_config["license"]}"
    consul_domain_name = "${var.consul_domain_name}"
    consul_acl_status = "${var.blue_consul_config_parameters["consul_acl_status"]}"
    acl_policy_ttl = "${var.blue_consul_config_parameters["acl_policy_ttl"]}"
    acl_token_ttl = "${var.blue_consul_config_parameters["acl_token_ttl"]}"
    acl_token_replication = "${var.blue_consul_config_parameters["acl_token_replication"]}"
    master_uuid = "${random_uuid.uuids.0.result}"
    agent_master_uuid = "${random_uuid.uuids.1.result}"
    grpc_port = "${var.grpc_port}"
  }
}

data "template_file" "green_consul_config" {
  count = "${var.is_green_mode_active == "yes" ? var.total_no_of_consul_servers["green"] : 0}"
  template = "${file("${var.green_consul_config_parameters["config_template"]}")}"
  vars {
    dc_name = "${local.dc_name}"
    acl_default_policy = "${var.green_consul_config_parameters["acl_default_policy"]}"
    acl_down_policy = "${var.green_consul_config_parameters["acl_down_policy"]}"
    autopilot_cleanup_dead_servers = "${var.green_consul_config_parameters["autopilot_cleanup_dead_servers"]}"
    autopilot_last_contact_threshold = "${var.green_consul_config_parameters["autopilot_last_contact_threshold"]}"
    autopilot_max_trailing_logs = "${var.green_consul_config_parameters["autopilot_max_trailing_logs"]}"
    autopilot_server_stablization_time = "${var.green_consul_config_parameters["autopilot_server_stablization_time"]}"
    autopilot_disable_upgrade_migration = "${var.green_consul_config_parameters["autopilot_disable_upgrade_migration"]}"
    number_of_consul_servers = "${var.total_no_of_consul_servers["green"]}"
    ca_path = "${var.green_consul_config_parameters["ca_path"]}"
    server_cert_file = "${var.green_consul_config_parameters["ssl_path"]}/${var.green_consul_config_parameters["server_cert_name"]}"
    check_update_interval = "${var.green_consul_config_parameters["check_update_interval"]}"
    data_dir = "${var.green_consul_config_parameters["data_dir"]}"
    disable_anonymous_signature = "${var.green_consul_config_parameters["disable_anonymous_signature"]}"
    disable_http_unprintable_char_filter = "${var.green_consul_config_parameters["disable_http_unprintable_char_filter"]}"
    disable_remote_exec = "${var.green_consul_config_parameters["disable_remote_exec"]}"
    disable_update_check = "${var.green_consul_config_parameters["disable_update_check"]}"
    discard_check_output = "${var.green_consul_config_parameters["discard_check_output"]}"
    discovery_max_stale = "${var.green_consul_config_parameters["discovery_max_stale"]}"
    dns_config_allow_stale = "${var.green_consul_config_parameters["dns_config_allow_stale"]}"
    dns_config_max_stale = "${var.green_consul_config_parameters["dns_config_max_stale"]}"
    dns_config_node_ttl = "${var.green_consul_config_parameters["dns_config_node_ttl"]}"
    dns_config_enable_truncate = "${var.green_consul_config_parameters["dns_config_enable_truncate"]}"
    dns_config_only_passing = "${var.green_consul_config_parameters["dns_config_only_passing"]}"
    dns_config_recursor_timeout = "${var.green_consul_config_parameters["dns_config_recursor_timeout"]}"
    dns_config_disable_compression = "${var.green_consul_config_parameters["dns_config_disable_compression"]}"
    domain_name = "${var.dhcp_domain}"
    enable_acl_replication = "${var.green_consul_config_parameters["enable_acl_replication"]}"
    enable_agent_tls_for_checks = "${var.green_consul_config_parameters["enable_agent_tls_for_checks"]}"
    enable_debug = "${var.green_consul_config_parameters["enable_debug"]}"
    enable_syslog = "${var.green_consul_config_parameters["enable_syslog"]}"
    encrypt_verify_incoming = "${var.green_consul_config_parameters["encrypt_verify_incoming"]}"
    encrypt_verify_outgoing = "${var.green_consul_config_parameters["encrypt_verify_outgoing"]}"
    server_key_file = "${var.green_consul_config_parameters["ssl_path"]}/${var.green_consul_config_parameters["server_cert_key"]}"
    leave_on_terminate = "${var.green_consul_config_parameters["leave_on_terminate"]}"
    log_level = "${var.green_consul_config_parameters["log_level"]}"
    instance_short_name = "${var.instance_short_name["consul"]}"
    deployment_mode = "green"
    environment = "${var.environment}"
    seq_number = "${count.index}"
    performance_leave_drain_Time = "${var.green_consul_config_parameters["performance_leave_drain_Time"]}"
    performance_raft_multiplier = "${var.green_consul_config_parameters["performance_raft_multiplier"]}"
    performance_rpc_hold_timeout = "${var.green_consul_config_parameters["performance_rpc_hold_timeout"]}"
    ports_https = "${var.consul_https_port}"
    ports_http = "${var.green_consul_config_parameters["ports_http"]}"
    reconnect_timeout = "${var.green_consul_config_parameters["reconnect_timeout"]}"
    dns_server = "${jsonencode(data.terraform_remote_state.basic-infra.dns_server)}"
    retry_join_tag_key = "${var.green_consul_config_parameters["retry_join_tag_key"]}"
    region = "${var.region}"
    retry_interval = "${var.green_consul_config_parameters["retry_interval"]}"
    skip_leave_on_interrupt = "${var.green_consul_config_parameters["skip_leave_on_interrupt"]}"
    telemetry_disable_hostname = "${var.green_consul_config_parameters["telemetry_disable_hostname"]}"
    telemetry_filter_default = "${var.green_consul_config_parameters["telemetry_filter_default"]}"
    telemetry_metrics_prefix = "${var.green_consul_config_parameters["telemetry_metrics_prefix"]}"
    tls_min_version = "${var.green_consul_config_parameters["tls_min_version"]}"
    tls_cipher_suites = "${var.green_consul_config_parameters["tls_cipher_suites"]}"
    tls_prefer_server_cipher_suites = "${var.green_consul_config_parameters["tls_prefer_server_cipher_suites"]}"
    ui = "${var.green_consul_config_parameters["ui"]}"
    verify_incoming = "${var.green_consul_config_parameters["verify_incoming"]}"
    verify_outgoing = "${var.green_consul_config_parameters["verify_outgoing"]}"
    verify_incoming_rpc = "${var.green_consul_config_parameters["verify_incoming_rpc"]}"
    verify_incoming_https = "${var.green_consul_config_parameters["verify_incoming_https"]}"
    verify_server_hostname = "${var.green_consul_config_parameters["verify_server_hostname"]}"
    consul_version = "${var.green_consul_user_data_config["version"]}"
    consul_license = "${var.green_consul_user_data_config["license"]}"
    consul_domain_name = "${var.consul_domain_name}"
    consul_acl_status = "${var.green_consul_config_parameters["consul_acl_status"]}"
    acl_policy_ttl = "${var.green_consul_config_parameters["acl_policy_ttl"]}"
    acl_token_ttl = "${var.green_consul_config_parameters["acl_token_ttl"]}"
    acl_token_replication = "${var.green_consul_config_parameters["acl_token_replication"]}"
    master_uuid = "${random_uuid.uuids.0.result}"
    agent_master_uuid = "${random_uuid.uuids.1.result}"
    grpc_port = "${var.grpc_port}"
  }
}



#-------------------------------------------------------------
### Template the user data files
#-------------------------------------------------------------
data "template_file" "blue-user-data-script" {
  count = "${var.is_blue_mode_active == "yes" ? local.len_blue_user_data * local.len_blue_servers : 0}"
  template =  "${file(var.blue_consul_user_data_scripts[count.index >= local.len_blue_user_data ? (count.index - local.len_blue_user_data) % local.len_blue_user_data : count.index % local.len_blue_user_data])}"
  vars {
    consul_volume_name = "${jsonencode(module.blue-consul-servers.ebs_volume_maps)}"
    backup_path = "${var.blue_consul_user_data_config["backup_path"]}"
    vg_names = "${jsonencode(var.blue_consul_vg_config["vg_names"])}"
    lv_names = "${jsonencode(var.blue_consul_vg_config["lv_names"])}"
    mount_points = "${jsonencode(var.blue_consul_vg_config["mount_points"])}"
    data_path = "${var.blue_consul_config_parameters["data_dir"]}"
    ssl_path = "${var.blue_consul_config_parameters["ssl_path"]}"
    ca_path = "${var.blue_consul_config_parameters["ca_path"]}"
    config_path = "${var.blue_consul_config_parameters["config_path"]}"
    user_name = "${var.user_name["consul"]}"
    group_name = "${var.group_name["consul"]}"
    user_id = "${var.user_id["consul"]}"
    group_id = "${var.group_id["consul"]}"
    consul_config_name = "${var.blue_consul_config_parameters["config_name"]}"
    consul_server_cert_name = "${var.blue_consul_config_parameters["server_cert_name"]}"
    consul_server_key_name = "${var.blue_consul_config_parameters["server_cert_key"]}"
    consul_config = "${data.template_file.blue_consul_config.*.rendered[count.index / local.len_blue_user_data]}"
    consul_server_cert = "${file("certs/blue-consul-server-${count.index / local.len_blue_user_data}.crt")}"
    consul_server_key = "${module.blue_consul_server_cert_key.private_key_pem[count.index / local.len_blue_user_data]}"
    consul_ca_path = "${var.blue_consul_config_parameters["ca_path"]}"
    consul_client_cert_name = "${var.blue_consul_config_parameters["client_cert_name"]}"
    consul_client_key_name = "${var.blue_consul_config_parameters["client_cert_key"]}"
    consul_client_cert = "${file("certs/blue-consul-client-${count.index / local.len_blue_user_data}.crt")}"
    consul_client_key = "${module.blue_consul_client_cert_key.private_key_pem[count.index / local.len_blue_user_data]}"
    consul_cidr = "${var.blue_consul_user_data_config["consul_cidr"]}"
    consul_docker_name = "blue-${var.environment}-${var.instance_short_name["consul"]}-${count.index / local.len_blue_user_data}"
    region = "${var.region}"
    consul_version = "${var.blue_consul_user_data_config["version"]}"
    consul_license = "${var.blue_consul_user_data_config["license"]}"
    https_port = "${var.consul_https_port}"
    host_name = "blue-${var.environment}-${var.instance_short_name["consul"]}.${var.dhcp_domain}"
    consul_server_name = "${var.environment}-${var.instance_short_name["consul"]}.${var.dhcp_domain}"
    consul_agent_token_name = "${local.consul_agent_token_name}"
    consul_agent_master_token_name  = "${local.consul_agent_master_token_name}"
    consul_replication_token_name = "${local.consul_replication_token_name}"
    consul_for_vault_management_token_name = "${local.consul_for_vault_management_token_name}"
    vault_backend_token_name = "${local.vault_backend_token_name}"
    environment = "${var.environment}"
    vault_token_ssm_path = "${var.vault_token_ssm_path}"
    dc_name = "${local.dc_name}"
    kms_key_id = "${jsonencode(data.terraform_remote_state.basic-infra.kms_key_id)}"
    consul_https_port = "${var.consul_https_port}"
    no_of_volumes_per_vg = "${jsonencode(var.blue_consul_vg_config["no_of_volumes_per_vg"])}"
    no_of_lvs_per_vg = "${jsonencode(var.blue_consul_vg_config["no_of_lvs_per_vg"])}"
    lv_frees = "${jsonencode(var.blue_consul_vg_config["lv_frees"])}"
    vault_kv_path = "${var.blue_vault_config_parameters["vault_path_in_consul"]}"
    vault_service_name = "${var.blue_vault_config_parameters["vault_service_name_in_consul"]}"
    restore_bucket_path = "${var.blue_consul_user_data_config["restore_bucket_path"]}"
    restore_from_backup = "${var.blue_consul_user_data_config["restore_from_backup"]}"
    BACKUP_FREQUENCY = "${var.blue_consul_config_parameters["BACKUP_FREQUENCY"]}"
    vault_slack_identifier = "${element(var.slack_project_code,0)}"
    slack_sns_topic_arn = "${data.terraform_remote_state.slack_topic.slack_sns_topic_arn}"
    backup_bucket = "${element(module.backup_bucket.bucket_id,0)}"
  }
}

data "template_file" "green-user-data-script" {
  count = "${var.is_green_mode_active == "yes" ? local.len_green_user_data * local.len_green_servers : 0}"
  template =  "${file(var.green_consul_user_data_scripts[count.index >= local.len_green_user_data ? (count.index - local.len_green_user_data) % local.len_green_user_data : count.index % local.len_green_user_data])}"
  vars {
    consul_volume_name = "${jsonencode(module.green-consul-servers.ebs_volume_maps)}"
    backup_path = "${var.green_consul_user_data_config["backup_path"]}"
    vg_names = "${jsonencode(var.green_consul_vg_config["vg_names"])}"
    lv_names = "${jsonencode(var.green_consul_vg_config["lv_names"])}"
    mount_points = "${jsonencode(var.green_consul_vg_config["mount_points"])}"
    data_path = "${var.green_consul_config_parameters["data_dir"]}"
    ssl_path = "${var.green_consul_config_parameters["ssl_path"]}"
    ca_path = "${var.green_consul_config_parameters["ca_path"]}"
    config_path = "${var.green_consul_config_parameters["config_path"]}"
    user_name = "${var.user_name["consul"]}"
    group_name = "${var.group_name["consul"]}"
    user_id = "${var.user_id["consul"]}"
    group_id = "${var.group_id["consul"]}"
    consul_config_name = "${var.green_consul_config_parameters["config_name"]}"
    consul_server_cert_name = "${var.green_consul_config_parameters["server_cert_name"]}"
    consul_server_key_name = "${var.green_consul_config_parameters["server_cert_key"]}"
    consul_config = "${data.template_file.green_consul_config.*.rendered[count.index / local.len_green_user_data]}"
    consul_server_cert = "${file("certs/green-consul-server-${count.index / local.len_green_user_data}.crt")}"
    consul_server_key = "${module.green_consul_server_cert_key.private_key_pem[count.index / local.len_green_user_data]}"
    consul_ca_path = "${var.green_consul_config_parameters["ca_path"]}"
    consul_client_cert_name = "${var.green_consul_config_parameters["client_cert_name"]}"
    consul_client_key_name = "${var.green_consul_config_parameters["client_cert_key"]}"
    consul_client_cert = "${file("certs/green-consul-client-${count.index / local.len_green_user_data}.crt")}"
    consul_client_key = "${module.green_consul_client_cert_key.private_key_pem[count.index / local.len_green_user_data]}"
    consul_cidr = "${var.green_consul_user_data_config["consul_cidr"]}"
    consul_docker_name = "green-${var.environment}-${var.instance_short_name["consul"]}-${count.index / local.len_green_user_data}"
    region = "${var.region}"
    consul_version = "${var.green_consul_user_data_config["version"]}"
    consul_license = "${var.green_consul_user_data_config["license"]}"
    https_port = "${var.consul_https_port}"
    host_name = "green-${var.environment}-${var.instance_short_name["consul"]}.${var.dhcp_domain}"
    consul_server_name = "${var.environment}-${var.instance_short_name["consul"]}.${var.dhcp_domain}"
    consul_agent_token_name = "${local.consul_agent_token_name}"
    consul_agent_master_token_name  = "${local.consul_agent_master_token_name}"
    consul_replication_token_name = "${local.consul_replication_token_name}"
    consul_for_vault_management_token_name = "${local.consul_for_vault_management_token_name}"
    vault_backend_token_name = "${local.vault_backend_token_name}"
    environment = "${var.environment}"
    vault_token_ssm_path = "${var.vault_token_ssm_path}"
    dc_name = "${local.dc_name}"
    kms_key_id = "${jsonencode(data.terraform_remote_state.basic-infra.kms_key_id)}"
    consul_https_port = "${var.consul_https_port}"
    no_of_volumes_per_vg = "${jsonencode(var.green_consul_vg_config["no_of_volumes_per_vg"])}"
    no_of_lvs_per_vg = "${jsonencode(var.green_consul_vg_config["no_of_lvs_per_vg"])}"
    lv_frees = "${jsonencode(var.green_consul_vg_config["lv_frees"])}"
    vault_kv_path = "${var.green_vault_config_parameters["vault_path_in_consul"]}"
    vault_service_name = "${var.green_vault_config_parameters["vault_service_name_in_consul"]}"
    restore_bucket_path = "${var.green_consul_user_data_config["restore_bucket_path"]}"
    restore_from_backup = "${var.green_consul_user_data_config["restore_from_backup"]}"
    BACKUP_FREQUENCY = "${var.green_consul_config_parameters["BACKUP_FREQUENCY"]}"
    vault_slack_identifier = "${element(var.slack_project_code,0)}"
    slack_sns_topic_arn = "${data.terraform_remote_state.slack_topic.slack_sns_topic_arn}"
    backup_bucket = "${element(module.backup_bucket.bucket_id,0)}"
  }
}

# Unforutnately, this has to be increased if the number of user data script changes

data "template_cloudinit_config" "blue-user-data-file" {
  count = "${var.is_blue_mode_active == "yes" ? var.total_no_of_consul_servers["blue"] : 0}"
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
  count = "${var.is_green_mode_active == "yes" ? var.total_no_of_consul_servers["green"] : 0}"
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
