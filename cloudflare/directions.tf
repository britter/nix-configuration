resource "cloudflare_record" "directions_host" {
  zone_id = var.cloudflare_zone_id
  name    = "directions"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "adguard" {
  zone_id = var.cloudflare_zone_id
  name    = "adguard"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "homepage" {
  zone_id = var.cloudflare_zone_id
  name    = "home"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "fritz_box" {
  zone_id = var.cloudflare_zone_id
  name    = "fritz-box"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "proxmox" {
  zone_id = var.cloudflare_zone_id
  name    = "proxmox"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "nextcloud_prod" {
  zone_id = var.cloudflare_zone_id
  name    = "nextcloud"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "collabora_prod" {
  zone_id = var.cloudflare_zone_id
  name    = "collabora"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "vaultwarden_prod" {
  zone_id = var.cloudflare_zone_id
  name    = "passwords"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "grafana_prod" {
  zone_id = var.cloudflare_zone_id
  name    = "grafana"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "nextcloud_test" {
  zone_id = var.cloudflare_zone_id
  name    = "nextcloud-test"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "collabora-test" {
  zone_id = var.cloudflare_zone_id
  name    = "collabora-test"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "vaultwarden-test" {
  zone_id = var.cloudflare_zone_id
  name    = "passwords-test"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}

