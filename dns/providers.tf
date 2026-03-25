terraform {
  backend "s3" {
    bucket                      = "tofu-states"
    key                         = "home-lab/dns/terraform.tfstate"
    region                      = "eu-central-1"
    endpoint                    = "https://minio.srv-prod-3-new.ritter.family"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.17"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

## Tailscale ##
variable "tailscale_api_token" {
  type = string
}

provider "tailscale" {
  api_key = var.tailscale_api_token
  tailnet = local.tailnet
}

## Cloudflare ##
variable "cloudflare_api_token" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
