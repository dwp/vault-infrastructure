path "/sys/rekey*" {
  capabilities = ["read","update","delete"]
}

path "/sys/rotate" {
  capabilities = ["update","sudo"]
}
