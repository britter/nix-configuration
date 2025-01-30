resource "cloudflare_record" "srv_test_1_wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*.srv-test-1"
  value   = "100.99.180.114"
  type    = "A"
  proxied = false
}

resource "cloudflare_api_token" "srv_test_1_acme_token" {
  name = "srv-test-1 acme token"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.${var.cloudflare_zone_id}" = "*"
    }
  }
}

output "srv_test_1_acme_token_value" {
  value     = cloudflare_api_token.srv_test_1_acme_token.value
  sensitive = true
}
