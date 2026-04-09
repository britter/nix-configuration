terraform {
  required_version = ">= 0.13.0"
  backend "s3" {
    bucket                      = "tofu-states"
    key                         = "home-lab/proxmox-new/terraform.tfstate"
    region                      = "eu-central-1"
    endpoint                    = "https://minio.srv-prod-3.ritter.family"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}

provider "sops" {}

data "sops_file" "secrets" {
  source_file = "secrets.json"
}

provider "proxmox" {
  pm_api_url          = data.sops_file.secrets.data["proxmox_new_api_url"]
  pm_api_token_id     = data.sops_file.secrets.data["proxmox_new_api_token_id"]
  pm_api_token_secret = data.sops_file.secrets.data["proxmox_new_api_token_secret"]

  # as long as I don't have HTTPS configured properly
  pm_tls_insecure = true
}
