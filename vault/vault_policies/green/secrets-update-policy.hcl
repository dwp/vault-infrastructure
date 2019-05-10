#This provides only capabilities to PKI, AWS, Consul and SSH which are vault admin or devops tasks. Do not add the secrets here
path "/secrets-pki-*" {
  capabilities = ["sudo","update","create"]
}

path "/secrets-aws-*" {
  capabilities = ["sudo","update","create"]
}

path "/secrets-ssh-*" {
  capabilities = ["sudo","update","create"]
}

path "/secrets-consul-*" {
  capabilities = ["sudo","update","create"]
}
