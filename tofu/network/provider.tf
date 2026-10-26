terraform {
  backend "s3" {
    bucket                      = "tofu-states-network"
    key                         = "terraform.tfstate"
    region                      = "garage"
    endpoint                    = "https://garage.srv-prod-3.ritter.family"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
  required_providers {
    unifi = {
      source  = "ubiquiti-community/unifi"
      version = "0.60.0"
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
