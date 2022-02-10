variable "azure_tenant_id" {
  description = "The tanant ID to be used in Hashicorp vault azure auth backend"
}

variable "aks_api_url" {
  description = "AKS cluster api url"
  type = string
  default = ""
}

variable "enable_aks_auth" {
  description = "Configure aks auth for hashicorp vault"
  type = bool
  default = false
}