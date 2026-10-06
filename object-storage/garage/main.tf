terraform {
  required_providers {
    garage = {
      source  = "registry.terraform.io/arsolitt/garagehq"
      version = ">= 0.0.1"
    }
  }
}

provider "garage" {
  host   = var.endpoint
  scheme = "https"
  token  = var.admin_token
}
