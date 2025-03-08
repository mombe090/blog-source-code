terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.86.0"
    }

    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}
