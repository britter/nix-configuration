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
      version = "0.54.1"
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

provider "unifi" {
  username       = data.sops_file.secrets.data["unifi_username"]
  password       = data.sops_file.secrets.data["unifi_password"]
  api_url        = data.sops_file.secrets.data["unifi_api_url"]
  allow_insecure = true
}
