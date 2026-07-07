terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.21.1"
    }
  }
}

# Required for managing API tokens
data "cloudflare_api_token_permission_groups_list" "all" {
}
