data "azurerm_client_config" "current" {
}

resource "vault_auth_backend" "azure" {
  type = "azure"
}

resource "azuread_application" "vault_app" {
  display_name = "${terraform.workspace}-hashicorp-vault-sp"
  owners           = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "vault_sp" {
  application_id = azuread_application.vault_app.application_id
  use_existing = true
}

resource "azuread_application_password" "vault_sp_password" {
  application_object_id = azuread_application.vault_app.object_id
  end_date              = "2040-01-01T00:00:00Z"
}

resource "azurerm_role_assignment" "vault_sp" {
  scope                            = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name             = "Reader"
  principal_id                     = azuread_service_principal.vault_sp.id
  skip_service_principal_aad_check = true
}

resource "vault_azure_auth_backend_config" "azure" {
  backend       = vault_auth_backend.azure.path
  tenant_id     = data.azurerm_client_config.current.tenant_id
  client_id     = azuread_application.vault_app.application_id
  client_secret = azuread_application_password.vault_sp_password.value
  resource      = "https://management.azure.com"
}

module "vault_kubernetes_auth_backend_module" {
  source = "../hashicorp-vault-auth-aks"
  count  = var.enable_aks_auth ? 1 : 0
}