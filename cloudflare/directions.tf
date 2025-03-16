resource "cloudflare_api_token" "directions_acme_token" {
  name = "directions acme token"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.${var.cloudflare_zone_id}" = "*"
    }
  }
}

output "directions_acme_token_value" {
  value     = cloudflare_api_token.directions_acme_token.value
  sensitive = true
}
