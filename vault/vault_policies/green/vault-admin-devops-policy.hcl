#  This policy is written in sections. The allowed ones are at the top, the example placeholders at the bottom and  which are not fully tested are at the middle

path "/sys/audit" {
  capabilities = ["sudo","read"]
}

path "/sys/audit-hash/*" {
  capabilities = ["update"]
}

path "/sys/auth" {
  capabilities = ["read"]
}

path "/sys/auth/*" {
  capabilities = ["sudo", "update","read"]
}

path "/sys/capabilities*" {
  capabilities = ["update"]
}

path "/sys/config/auditing/*" {
  capabilities = ["update", "sudo", "read"]
}

path "/sys/config/cors" {
  capabilities = ["sudo","read"]
}

path "/sys/config/ui/*" {
  capabilities = ["sudo","read","list"]
}

path "/sys/key-status" {
  capabilities = ["read"]
}

path "/sys/mounts" {
  capabilities = ["read"]
}

path "/sys/mounts/*" {
  capabilities = ["update","read"]
}

path "/sys/internal/ui/mounts" {
  capabilities = ["read"]
}

path "/sys/policy" {
  capabilities = ["read"]
}

path "/sys/policy/*" {
  capabilities = ["read"]
}

path "/sys/policies/*" {
  capabilities = ["read","list"]
}

path "/sys/remount" {
  capabilities = ["sudo","update"]
}

path "/sys/step-down" {
  capabilities = ["sudo","update"]
}

path "/sys/tools/*" {
  capabilities = ["update"]
}

path "/auth/*" {
  capabilities = ["list","read"]
}

path "/auth/token/lookup" {
  capabilities = ["sudo","update"]
}

#---------- Allow Secrets PKI, AWS, Consul and SSH Read Access -------
path "/secrets-pki-*" {
  capabilities = ["read","list"]
}
path "/secrets-aws-*" {
  capabilities = ["read","list"]
}
path "/secrets-consul-*" {
  capabilities = ["read","list"]
}
path "/secrets-ssh-*" {
  capabilities = ["read","list"]
}
path "/secrets-pki-int-ca*" {
  capabilities = ["update","read","list"]
}
path "/secrets-infra/*" {
  capabilities = ["read","update","list","delete","create"]
}

#--------- Not tested as there is not requirement for this now -------
path "/sys/leases/*" {
  capabilities = ["update","read"]
}

path "/sys/leases/revoke" {
  capabilities = ["sudo","update"]
}

path "/sys/leases/revoke-*/*" {
  capabilities = ["sudo","update"]
}

path "/sys/plugins/*" {
  capabilities = ["sudo","update", "list","read"]
}

# ------------  Enterprise Only Features. NOT TESTED -------------
path "/sys/config/control-group" {
  capabilities = ["update","read"]
}

path "/sys/policies/egp/" {
  capabilities = ["list"]
}

path "/sys/policies/rgp/" {
  capabilities = ["list"]
}

path "/sys/replication/*" {
  capabilities = ["update","read"]
}

path "/sys/license" {
  capabilities = ["update","read"]
}

path "/sys/namespaces/*" {
  capabilities = ["update","read","list"]
}

path "/sys/mfa/*" {
  capabilities = ["update","read"]
}

#------------------------------------------------------------------------------------
# These are unauthenticated endpoints where anybody can initiate this
#------------------------------------------------------------------------------------
#path "/sys/generate-root/attempt"
#path "/sys/health"
#path "/sys/init"
#path "/sys/leader"
#path "/sys/rekey*" # Except for retreiving and deleting backup keys, these does not require authentication
#path "/sys/seal-status"
#path "/sys/unseal"

#The following paths is by default to all authenticated users
#path "/sys/wrapping"
#path "/sys/init"
