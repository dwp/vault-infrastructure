path "/sys/*" {
  capabilities = ["sudo","update"]
}

path "/sys/seal" {
  capabilities = ["deny"]
}
