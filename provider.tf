terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.56.0"
    }
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
  use_cli             = false
  storage_use_azuread = true
}