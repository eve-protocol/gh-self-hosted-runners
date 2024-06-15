terraform {
  required_version = ">= 1.8.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0, < 4.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0.0, < 3.0.0"
    }
  }
  cloud {
    organization = "eve-protocol"
    workspaces {
      name = "gh-runners"
    }
  }
}

provider "azurerm" {
  features {
  }
  subscription_id     = "4d57a08b-6580-4740-8e38-a43f92a60089"
  storage_use_azuread = true
}

provider "azuread" {
}
