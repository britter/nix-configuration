terraform {
  backend "s3" {
    bucket                      = "tofu-states"
    key                         = "home-lab/network/terraform.tfstate"
    region                      = "eu-central-1"
    endpoint                    = "https://minio.srv-prod-3.ritter.family"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
  required_providers {
    unifi = {
      source  = "ubiquiti-community/unifi"
      version = "0.41.25-britter"
    }
  }
}

variable "unifi_username" {
  type = string
}

variable "unifi_password" {
  type = string
}

variable "unifi_api_url" {
  type = string
}

provider "unifi" {
  username       = var.unifi_username
  password       = var.unifi_password
  api_url        = var.unifi_api_url
  allow_insecure = true
}
