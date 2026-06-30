terraform {
  required_version = ">= 1.13"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.10"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.14"
    }
  }
}

provider "azapi" {}
