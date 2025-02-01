resource "cloudflare_record" "srv_prod_1_wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*.srv-prod-1"
  content = "100.95.93.72"
  type    = "A"
  proxied = false
}

resource "cloudflare_api_token" "srv_prod_1_acme_token" {
  name = "srv-prod-1 acme token"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.${var.cloudflare_zone_id}" = "*"
    }
  }
}

output "srv_prod_1_acme_token_value" {
  value     = cloudflare_api_token.srv_prod_1_acme_token.value
  sensitive = true
}
