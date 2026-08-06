terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.23.0"
    }
  }
}

# Required for managing API tokens
data "cloudflare_api_token_permission_groups_list" "all" {
}
