terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.10"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.10"
    }
  }

  # Remote state is strongly recommended for anything beyond a personal lab.
  # State for this project contains tenant object IDs and policy details.
  # Uncomment and fill in to use an Azure Storage backend (see README).
  # backend "azurerm" {}
}
