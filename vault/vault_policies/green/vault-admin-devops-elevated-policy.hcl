path "/auth/token/roles/*" {
  capabilities = ["sudo","list","read","create","update","delete"]
}

path "/auth/token/create*" {
  capabilities = ["read","create","update","sudo","list","delete"]
}

path "/auth/token/renew" {
  capabilities = ["sudo","update"]
}

path "/auth/token/revoke" {
  capabilities = ["sudo","update"]
}

path "/auth/token/lookup" {
  capabilities = ["sudo","update"]
}

path "/secrets-infra*" {
  capabilities = ["read","list"]
}
