# Authentication is NOT configured here on purpose. Sign in with `az login`
# (or use OIDC from a CI pipeline). Never put client secrets in this repo.

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
