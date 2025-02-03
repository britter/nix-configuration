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
