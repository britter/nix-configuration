resource "cloudflare_record" "srv_prod_2_wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*.srv-prod-2"
  content = "100.94.107.46"
  type    = "A"
  proxied = false
}

resource "cloudflare_api_token" "srv_prod_2_acme_token" {
  name = "srv-prod-2 acme token"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.${var.cloudflare_zone_id}" = "*"
    }
  }
}

output "srv_prod_2_acme_token_value" {
  value     = cloudflare_api_token.srv_prod_2_acme_token.value
  sensitive = true
}
