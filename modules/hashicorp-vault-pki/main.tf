resource "vault_pki_secret_backend" "pki_root" {
  path                      = var.root_pki_path
  default_lease_ttl_seconds = var.root_pki_lease_ttl
  max_lease_ttl_seconds     = var.root_pki_max_lease_ttl
  description               = "Root CA"
}

resource "vault_pki_secret_backend" "pki_intermediate_primary" {
  path                      = var.intermediate_pki_path_primary
  default_lease_ttl_seconds = var.intermediate_pki_lease_ttl_primary
  max_lease_ttl_seconds     = var.intermediate_pki_max_lease_ttl_primary
  depends_on                = ["vault_pki_secret_backend.pki_root"]
}

resource "vault_pki_secret_backend" "pki_intermediate_secondary" {
  count                     = var.rotate_intermediate_primary ? 1 : 0
  path                      = var.intermediate_pki_path_secondary
  default_lease_ttl_seconds = var.intermediate_pki_lease_ttl_secondary
  max_lease_ttl_seconds     = var.intermediate_pki_max_lease_ttl_secondary
  depends_on                = ["vault_pki_secret_backend.pki_root"]
}

resource "vault_pki_secret_backend_root_cert" "root" {
  depends_on = ["vault_pki_secret_backend.pki_root"]

  backend = vault_pki_secret_backend.pki_root.path

  type                 = "internal"
  common_name          = var.ca_common_name
  ttl                  = var.root_pki_max_lease_ttl
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = var.ca_ou_name
  organization         = var.ca_organization_name
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate_primary" {
  depends_on = ["vault_pki_secret_backend.pki_intermediate_primary"]

  backend = vault_pki_secret_backend.pki_intermediate_primary.path

  type        = "internal"
  common_name = var.primary_intermediate_common_name
}

resource "vault_pki_secret_backend_root_sign_intermediate" "root_intermediate_primary" {
  depends_on = ["vault_pki_secret_backend_intermediate_cert_request.intermediate_primary"]

  backend = vault_pki_secret_backend.pki_root.path

  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate_primary.csr
  common_name          = var.primary_intermediate_common_name
  exclude_cn_from_sans = true
  ttl                  = var.intermediate_pki_max_lease_ttl_primary
  ou                   = var.intermediate_ou_primary_name
  organization         = var.intermediate_organization_primary_name
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate_primary" {
  depends_on = ["vault_pki_secret_backend_root_sign_intermediate.root_intermediate_primary"]

  backend = vault_pki_secret_backend.pki_intermediate_primary.path

  certificate = vault_pki_secret_backend_root_sign_intermediate.root_intermediate_primary.certificate
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate_secondary" {
  count      = var.rotate_intermediate_primary ? 1 : 0
  depends_on = ["vault_pki_secret_backend.pki_intermediate_secondary"]

  backend = vault_pki_secret_backend.pki_intermediate_secondary[0].path

  type        = "internal"
  common_name = var.secondary_intermediate_common_name
}

resource "vault_pki_secret_backend_root_sign_intermediate" "root_intermediate_secondary" {
  count      = var.rotate_intermediate_primary ? 1 : 0
  depends_on = ["vault_pki_secret_backend_intermediate_cert_request.intermediate_secondary"]

  backend = vault_pki_secret_backend.pki_root.path

  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate_secondary[0].csr
  common_name          = var.secondary_intermediate_common_name
  exclude_cn_from_sans = true
  ttl                  = var.intermediate_pki_max_lease_ttl_secondary
  ou                   = var.intermediate_ou_secondary_name
  organization         = var.intermediate_organization_secondary_name
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate_secondary" {
  count      = var.rotate_intermediate_primary ? 1 : 0
  depends_on = ["vault_pki_secret_backend_root_sign_intermediate.root_intermediate_secondary"]

  backend = vault_pki_secret_backend.pki_intermediate_secondary[0].path

  certificate = vault_pki_secret_backend_root_sign_intermediate.root_intermediate_secondary[0].certificate
}

resource "vault_pki_secret_backend_role" "azure_pki_int_roles_primary" {
  for_each = { for role in var.azure_pki_int_roles : role.name => role }

  backend = vault_pki_secret_backend.pki_intermediate_primary.path
  name    = each.value["name"]

  allowed_domains  = [each.value["allowed_domains"]]
  allow_subdomains = each.value["allow_subdomains"]
  generate_lease   = each.value["generate_lease"]
  max_ttl          = each.value["max_ttl"]
  key_usage        = each.value["key_usage"]
}

resource "vault_pki_secret_backend_role" "azure_pki_int_roles_secondary" {
  for_each = { for role in var.azure_pki_int_roles : role.name => role if var.rotate_intermediate_primary } 

  backend = vault_pki_secret_backend.pki_intermediate_secondary[0].path
  name    = each.value["name"]

  allowed_domains  = [each.value["allowed_domains"]]
  allow_subdomains = each.value["allow_subdomains"]
  generate_lease   = each.value["generate_lease"]
  max_ttl          = each.value["max_ttl"]
  key_usage        = each.value["key_usage"]
}

resource "vault_pki_secret_backend_role" "aks_pki_int_roles_primary" {
  for_each = { for role in var.aks_pki_int_roles : role.name => role }

  backend = vault_pki_secret_backend.pki_intermediate_primary.path
  name    = each.value["name"]

  allowed_domains  = [each.value["allowed_domains"]]
  allow_subdomains = each.value["allow_subdomains"]
  generate_lease   = each.value["generate_lease"]
  max_ttl          = each.value["max_ttl"]
  key_usage        = each.value["key_usage"]
}

resource "vault_pki_secret_backend_role" "aks_pki_int_roles_secondary" {
  for_each = { for role in var.aks_pki_int_roles : role.name => role if var.rotate_intermediate_primary }

  backend = vault_pki_secret_backend.pki_intermediate_primary.path
  name    = each.value["name"]

  allowed_domains  = [each.value["allowed_domains"]]
  allow_subdomains = each.value["allow_subdomains"]
  generate_lease   = each.value["generate_lease"]
  max_ttl          = each.value["max_ttl"]
  key_usage        = each.value["key_usage"]
}

resource "vault_policy" "zookeeper_test_primary" {
  name = "zookeeper-test"

  policy = <<EOT
path "pki_int_primary/issue/zookeeper-test" {
  capabilities = [ "create","update","read" ]
}
path "pki_int_primary/cert/ca" {
  capabilities = [ "read" ]
}
path "pki/cert/ca" {
  capabilities = [ "read" ]
}
EOT
}

resource "vault_policy" "zookeeper_test_secondary" {
  count = var.rotate_intermediate_primary ? 1 : 0
  name  = "zookeeper-test"

  policy = <<EOT
path "pki_int_secondary/issue/zookeeper-test" {
  capabilities = [ "create","update","read" ]
}
path "pki_int_secondary/cert/ca" {
  capabilities = [ "read" ]
}
path "pki/cert/ca" {
  capabilities = [ "read" ]
}
EOT
}

resource "vault_policy" "zookeeper_primary" {
  name = "zookeeper"

  policy = <<EOT
path "pki_int_primary/issue/zookeeper" {
  capabilities = [ "create","update","read" ]
}
path "pki_int_primary/cert/ca" {
  capabilities = [ "read" ]
}
path "pki/cert/ca" {
  capabilities = [ "read" ]
}
EOT
}

resource "vault_policy" "zookeeper_secondary" {
  count = var.rotate_intermediate_primary ? 1 : 0
  name = "zookeeper"

  policy = <<EOT
path "pki_int_secondary/issue/zookeeper" {
  capabilities = [ "create","update","read" ]
}
path "pki_int_secondary/cert/ca" {
  capabilities = [ "read" ]
}
path "pki/cert/ca" {
  capabilities = [ "read" ]
}
EOT
}

resource "vault_policy" "kafka_test_primary" {
  name = "kafka-test"

  policy = <<EOT
path "pki_int_primary/issue/kafka-test" {
  capabilities = ["create", "update", "read" ]
}
path "pki_int_primary/cert/ca" {
  capabilities = [ "read" ]
}
path "pki/cert/ca" {
  capabilities = [ "read" ]
}
EOT
}

resource "vault_policy" "kafka_test_secondary" {
  count = var.rotate_intermediate_primary ? 1 : 0
  name  = "kafka-test"

  policy = <<EOT
path "pki_int_secondary/issue/kafka-test" {
  capabilities = ["create", "update", "read" ]
}
path "pki_int_secondary/cert/ca" {
  capabilities = [ "read" ]
}
path "pki/cert/ca" {
  capabilities = [ "read" ]
}
EOT
}

resource "vault_policy" "kafka_primary" {
  name = "kafka"

  policy = <<EOT
path "pki_int_primary/issue/kafka" {
  capabilities = ["create", "update", "read" ]
}
path "pki_int_primary/cert/ca" {
  capabilities = [ "read" ]
}
path "pki/cert/ca" {
  capabilities = [ "read" ]
}
EOT
}

resource "vault_policy" "kafka_secondary" {
  count = var.rotate_intermediate_primary ? 1 : 0
  name = "kafka"

  policy = <<EOT
path "pki_int_primary/issue/kafka" {
  capabilities = ["create", "update", "read" ]
}
path "pki_int_primary/cert/ca" {
  capabilities = [ "read" ]
}
path "pki/cert/ca" {
  capabilities = [ "read" ]
}
EOT
}

resource "vault_policy" "aks_default" {
  name = "aks-default"

  policy = <<EOT
path "pki_int/issue/aks-test" {
  capabilities = ["create", "update", "read" ]
}
path "pki_int/sign/aks-default" {
  capabilities = ["create", "update", "read" ]
}
EOT
}

resource "vault_azure_auth_backend_role" "azure_auth_role_rg_bound" {
  for_each = { for role in var.azure_pki_int_roles : role.name => role if var.resource_group_id != "" }

  backend                = var.auth_azure_path
  role                   = each.value["name"]
  bound_subscription_ids = [var.subscription_id]
  bound_resource_groups  = [var.resource_group_id]
  token_ttl              = each.value["azure_role_ttl"]
  token_max_ttl          = var.azure_role_max_ttl
  token_policies         = [each.value["name"]]
}

resource "vault_azure_auth_backend_role" "azure_auth_role_subscription_bound" {
  for_each = { for role in var.azure_pki_int_roles : role.name => role if var.resource_group_id == "" }

  backend                = var.auth_azure_path
  role                   = each.value["name"]
  bound_subscription_ids = [var.subscription_id]
  token_ttl              = try(each.value["azure_role_ttl"], "31556952")
  token_max_ttl          = var.azure_role_max_ttl
  token_policies         = [each.value["name"]]
}

resource "vault_kubernetes_auth_backend_role" "aks_auth_role" {
  for_each = { for role in var.aks_pki_int_roles : role.name => role if var.auth_aks_path != "" }

  backend                          = var.auth_aks_path
  role_name                        = each.value["name"]
  bound_service_account_names      = each.value["service_account"]
  bound_service_account_namespaces = each.value["service_account_namespaces"]
  token_ttl                        = var.aks_role_ttl
  token_max_ttl                    = var.aks_role_max_ttl
  token_policies                   = [each.value["name"]]
}
