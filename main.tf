terraform {
  required_version = ">= 0.13.0"
  backend "azurerm" {
    container_name       = "tfstate"
    key                  = "hashicorp-vault-config.terraform.tfstate"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "2.6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.90.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {
}

provider "vault" {
  address      = "https://vault.cloud.${terraform.workspace}.example.com"
  ca_cert_file = "/ca-vault.crt"
}

module "vault_auth_config" {
  source = "../modules/hashicorp-vault-auth"

  azure_tenant_id = data.azurerm_client_config.current.tenant_id
}

module "vault_pki_config" {
  source = "../modules/hashicorp-vault-pki"

  azure_pki_int_roles = local.azure_pki_int_roles
  aks_pki_int_roles   = local.aks_pki_int_roles
  pki_root_roles      = local.pki_root_roles

  rotate_intermediate_primary = false
  rotate_intermediate_secondary = false

  primary_intermediate_common_name = "vm.${terraform.workspace}.internal"
  secondary_intermediate_common_name = "vm.${terraform.workspace}.internal"
  ca_common_name = "vm.${terraform.workspace}.internal"
  auth_azure_path   = module.vault_auth_config.auth_azure_path
  subscription_id   = data.azurerm_client_config.current.subscription_id
}

locals {
  aks_pki_int_roles = yamldecode(replace(file("./env/${terraform.workspace}/aks_pki_int_roles.yaml"),"{terraform.workspace}", terraform.workspace))
  azure_pki_int_roles = yamldecode(replace(file("./env/${terraform.workspace}/azure_pki_int_roles.yaml"),"{terraform.workspace}", terraform.workspace))
  pki_root_roles = yamldecode(replace(file("./env/${terraform.workspace}/pki_root_roles.yaml"),"{terraform.workspace}", terraform.workspace))
}


