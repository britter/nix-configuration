terraform {
  backend "s3" {
    bucket                      = "tofu-states-dns"
    key                         = "terraform.tfstate"
    region                      = "garage"
    endpoint                    = "https://garage.srv-prod-3.ritter.family"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.29.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.28.1"
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

## Tailscale ##
provider "tailscale" {
  api_key = data.sops_file.secrets.data["tailscale_api_token"]
  tailnet = local.tailnet
}

## Cloudflare ##
provider "cloudflare" {
  api_token = data.sops_file.secrets.data["cloudflare_api_token"]
}
