# terraform_module_vault_pki
Terraform module to configure Hashicorp Vault PKI and Auth methods
This module is created for Microsoft Azure services
This modules creates [authorization configuration](https://www.vaultproject.io/docs/auth/azure) for Azure and Azure Kubernetes (AKS).
Module consists of root module, that calls two other modules.
Module respects terraform workspaces, just set the workspace and its name will be passed as suffix to yaml files, that are stored as input config in var/ folder.

# Requirements:
Hashicorp Vault needs to be installed and initialiazed.
Root token or token with admin rights can be used to configure Hashicorp Vault with this module.
If you use self signed TLS certificate for Hashicorp Vault endpoint, you need to provide it to the module.
