#This provides only capabilities to PKI, AWS and SSH which are vault admin or devops tasks. Do not add the secrets here
path "/secrets-pki-*" {
  capabilities = ["sudo","delete"]
}

path "/secrets-aws-*" {
  capabilities = ["sudo","delete"]
}

path "/secrets-ssh-*" {
  capabilities = ["sudo","delete"]
}

path "/secrets-consul-*" {
  capabilities = ["sudo","delete"]
}
