terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.17.2"
    }
  }
}

variable "tailscape_api_token" {
  type = string
}

locals {
  tailnet = "tail74798e.ts.net"
  devices = ["srv-eval-1", "srv-test-1", "srv-test-2", "srv-prod-1", "srv-prod-2", "directions"]
}

provider "tailscale" {
  api_key = var.tailscape_api_token
  tailnet = local.tailnet
}
