// Enable or Disable UI feature of the VAULT
ui = "${ui}"

cluster_name = "${vault_cluster_name}"
cache_size = "${cache_size}"
disable_cache = "${disable_cache}"

// Make sure the mlock is disabled
disable_mlock = true

plugin_directory = "${vault_plugin_directory}"
log_level = "${vault_log_level}"


// Make sure this is disabled
raw_storage_endpoint = false

// HA Parameters
api_addr = "https://${node_name}-${seq_number}.${domain_name}:${vault_port}"
cluster_addr = "https://${node_name}-${seq_number}.${domain_name}:${vault_cluster_port}"
disable_clustering = "${disable_clustering}"

//Enterprise parameters. Commented to be used during enterprise edition
//disable_sealwrap = insert_value_default_is_false
//disable_performance_standby = insert_value_default_is_false

seal "awskms" {
  region = "${region}"
  kms_key_id = "${kms_key_id}"
}

storage "consul" {
    address = "${node_name}-${seq_number}.${domain_name}:${consul_https_port}"
    check_timeout = "${consul_agent_check_timeout}"
    consistency_mode = "${consul_agent_consistency_mode}"
    disable_registration = "${consul_agent_disable_registration}"
    max_parallel = "${consul_agent_max_parallel}"
    path = "${vault_path_in_consul}/"
    scheme = "${consul_agent_connection_method}"
    service = "${vault_service_name_in_consul}"
    service_tags = "${vault_service_tags_in_consul}"
    service_address = "${vault_service_addrs_in_consul}"
    token = "{vault_storage_backend_token}"
    session_ttl = "${consul_agent_session_ttl}"
    local_wait_time = "${consul_agent_lock_wait_time}"
    tls_ca_file = "${ca_file}"
    tls_cert_file = "${consul_client_cert_file}"
    tls_key_file = "${consul_client_key_file}"
    tls_min_version = "${tls_min_version}"
    tls_skip_verify = "${consul_agent_tls_skip_verify}"
}

// VAULT Listener configuration

listener "tcp" {
  address = "{node_ip}:${vault_port}"
  cluster_address = "{node_ip}:${vault_cluster_port}"
  max_request_size = ${max_request_size}
  proxy_protocol_behaviour = "${proxy_protocol_behaviour}"
  proxy_protocol_authorized_addrs = "${proxy_protocol_authorized_addrs}"
  tls_disable = "${tls_disable}"
  tls_cert_file = "${server_cert_file}"
  tls_key_file = "${server_key_file}"
  tls_min_version = "${tls_min_version}"
  tls_cipher_suites = "${tls_cipher_suites}"
  tls_prefer_server_cipher_suites = "${tls_prefer_server_cipher_suites}"
  tls_require_and_verify_client_cert = "${tls_require_and_verify_client_cert}"
  tls_client_ca_file = "${ca_file}"
  tls_disable_client_certs = "${tls_disable_client_certs}"

  // Not setting any X-Forwarded-For header settings, as it is not being used now. See documentation for more details

}

//Disable Telemetry until it is setup
telemetry {
  disable_hostname = ${telemetry_disable_hostname}
  statsd_address = "{node_ip}:<statsd_port>"
}
