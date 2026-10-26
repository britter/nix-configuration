terraform {
  backend "s3" {
    bucket                      = "tofu-states-object-storage"
    key                         = "terraform.tfstate"
    region                      = "garage"
    endpoint                    = "https://garage.srv-prod-3.ritter.family"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
    garage = {
      source  = "registry.terraform.io/arsolitt/garagehq"
      version = ">= 0.0.1"
    }
  }
}

provider "sops" {}

data "sops_file" "secrets" {
  source_file = "secrets.json"
}

module "srv-prod-3-garage" {
  source      = "./garage"
  endpoint    = "garage.srv-prod-3.ritter.family:443"
  admin_token = data.sops_file.secrets.data["srv_prod_3_garage_admin_token"]
}
