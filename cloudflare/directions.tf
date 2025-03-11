locals {
  services = [
    "adgurad",
    "homepage",
    "fritz-box",
    "grafana",
    "proxmox",
    "nextcloud",
    "nextcloud-test",
    "collabora",
    "collabora-test",
    "passwords",
    "passwords-test",
  ]
}

resource "cloudflare_record" "directions_host" {
  zone_id = var.cloudflare_zone_id
  name    = "directions"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "directions_exposed_service" {
  for_each = toset(local.services)
  zone_id  = var.cloudflare_zone_id
  name     = each.key
  content  = var.host_ips["directions"]
  type     = "A"
  proxied  = false
}

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
