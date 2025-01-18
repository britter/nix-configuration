resource "cloudflare_record" "srv_test_2_wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*.srv-test-2"
  value   = "srv-test-2.tail74798e.ts.net"
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "nextcloud_test" {
  zone_id = var.cloudflare_zone_id
  name    = "nextcloud-test"
  value   = "srv-test-2.tail74798e.ts.net"
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "collabora-test" {
  zone_id = var.cloudflare_zone_id
  name    = "collabora-test"
  value   = "srv-test-2.tail74798e.ts.net"
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "vaultwarden-test" {
  zone_id = var.cloudflare_zone_id
  name    = "passwords-test"
  value   = "srv-test-2.tail74798e.ts.net"
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_api_token" "srv_test_2_acme_token" {
  name = "srv-test-2 acme token"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.${var.cloudflare_zone_id}" = "*"
    }
  }
}

output "srv_test_2_acme_token_value" {
  value     = cloudflare_api_token.srv_test_2_acme_token.value
  sensitive = true
}
