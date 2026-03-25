terraform {
  required_version = ">= 0.13.0"
  backend "s3" {
    bucket                      = "tofu-states"
    key                         = "home-lab/proxmox/terraform.tfstate"
    region                      = "eu-central-1"
    endpoint                    = "https://minio.srv-prod-3-new.ritter.family"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc2"
    }
  }
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  # as long as I don't have HTTPS configured properly
  pm_tls_insecure = true
}
