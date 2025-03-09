data "vault_policy_document" "tuto_policy_document" {
  rule {
    path         = "tuto/*"
    capabilities = ["read", "list"]
    description  = "Autorise la lecture des secrets de tuto/* par le role tuto"
  }

  rule {
    path         = "auth/token/lookup-self"
    capabilities = ["read", "update"]
    description  = "Autorise la lecture des secrets de tuto/* par le role tuto"
  }
}

# Mount the KV secrets engine at "secrets" with version 2
resource "vault_mount" "secret" {
  path = "secrets"
  type = "kv"
  options = {
    version = "2"
  }
}

resource "vault_policy" "tuto_policy" {
  name   = "tuto"
  policy = data.vault_policy_document.tuto_policy_document.hcl
}

resource "vault_token_auth_backend_role" "example" {
  role_name              = "my-role"
  allowed_policies       = ["tuto"]
  disallowed_policies    = ["default", "root"]
  orphan                 = true
  token_period           = "86400"
  renewable              = true
  token_explicit_max_ttl = "115200"
}

resource "vault_token" "example" {
  role_name = "my-role"

  policies = ["tuto"]

  renewable = true
  ttl       = "24h"

  renew_min_lease = 43200
  renew_increment = 86400

  metadata = {
    "purpose" = "external-secret-eso"
  }
}
