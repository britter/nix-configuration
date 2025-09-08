terraform {
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
