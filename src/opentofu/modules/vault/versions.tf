terraform {
  required_version = ">= 1.9.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "4.6.0"
    }
  }
}

provider "vault" {
  address = var.vault_adress
  token   = var.vault_root_token
}
