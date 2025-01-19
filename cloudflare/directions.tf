locals {
  directions_tailscale_name = "directions.tail74798e.ts.net"
}

resource "cloudflare_record" "directions_host" {
  zone_id = var.cloudflare_zone_id
  name    = "directions"
  value   = local.directions_tailscale_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "adguard" {
  zone_id = var.cloudflare_zone_id
  name    = "adguard"
  value   = local.directions_tailscale_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "homepage" {
  zone_id = var.cloudflare_zone_id
  name    = "home"
  value   = local.directions_tailscale_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "fritz_box" {
  zone_id = var.cloudflare_zone_id
  name    = "fritz-box"
  value   = local.directions_tailscale_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "proxmox" {
  zone_id = var.cloudflare_zone_id
  name    = "proxmox"
  value   = local.directions_tailscale_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "nextcloud_prod" {
  zone_id = var.cloudflare_zone_id
  name    = "nextcloud"
  value   = local.directions_tailscale_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "collabora_prod" {
  zone_id = var.cloudflare_zone_id
  name    = "collabora"
  value   = local.directions_tailscale_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "vaultwarden_prod" {
  zone_id = var.cloudflare_zone_id
  name    = "passwords"
  value   = local.directions_tailscale_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "grafana_prod" {
  zone_id = var.cloudflare_zone_id
  name    = "grafana"
  value   = local.directions_tailscale_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "nextcloud_test" {
  zone_id = var.cloudflare_zone_id
  name    = "nextcloud-test"
  value   = local.directions_tailscale_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "collabora-test" {
  zone_id = var.cloudflare_zone_id
  name    = "collabora-test"
  value   = local.directions_tailscale_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "vaultwarden-test" {
  zone_id = var.cloudflare_zone_id
  name    = "passwords-test"
  value   = local.directions_tailscale_name
  type    = "CNAME"
  proxied = false
}

