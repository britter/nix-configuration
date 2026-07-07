terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.52.8"
    }
  }
}

# Required for managing API tokens
data "cloudflare_api_token_permission_groups" "all" {}
