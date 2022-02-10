variable "root_pki_path" {
  type    = string
  default = "pki"
}

variable "root_pki_lease_ttl" {
  type    = string
  default = "315360000"
}

variable "root_pki_max_lease_ttl" {
  type    = string
  default = "315360000"
}

variable "intermediate_pki_path_primary" {
  type    = string
  default = "pki_int_primary"
}

variable "intermediate_pki_lease_ttl_primary" {
  type    = string
  default = "94608000"
}

variable "intermediate_pki_max_lease_ttl_primary" {
  type    = string
  default = "94608000"
}

variable "intermediate_pki_path_secondary" {
  type    = string
  default = "pki_int_secondary"
}

variable "intermediate_pki_lease_ttl_secondary" {
  type    = string
  default = "17280000"
}

variable "intermediate_pki_max_lease_ttl_secondary" {
  type    = string
  default = "17280000"
}

variable "azure_role_ttl" {
  type    = string
  default = "31556952"
}

variable "aks_role_max_ttl" {
  type    = string
  default = "86400"
}

variable "aks_role_ttl" {
  type    = string
  default = "86400"
}

variable "azure_role_max_ttl" {
  type    = string
  default = "31556952"
}

variable "ca_common_name" {
  type    = string
}

variable "primary_intermediate_common_name" {
  type    = string
}

variable "secondary_intermediate_common_name" {
  type    = string
}
variable "ca_ou_name" {
  type    = string
  default = "root"
}

variable "intermediate_ou_primary_name" {
  type    = string
  default = "intermediate-primary"
}

variable "intermediate_ou_secondary_name" {
  type    = string
  default = "intermediate-secondary"
}

variable "ca_organization_name" {
  type    = string
  default = "Org"
}

variable "intermediate_organization_primary_name" {
  type    = string
  default = "vault-primary"
}

variable "intermediate_organization_secondary_name" {
  type    = string
  default = "vault-secondary"
}

variable "pki_root_roles" {
  type = list(any)
}

variable "azure_pki_int_roles" {
  type = list(any)
}

variable "aks_pki_int_roles" {
  type = list(any)
  default = []
}

variable "auth_azure_path" {
  type = string
}

variable "auth_aks_path" {
  type = string
  default = ""
}

variable "subscription_id" {
  type = string
}

variable "resource_group_id" {
  type = string
  default = ""
}

variable "rotate_intermediate_primary" {
  type = bool
  default = false
}

variable "rotate_intermediate_secondary" {
  type = bool
  default = false
}
