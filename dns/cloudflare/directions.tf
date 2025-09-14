resource "cloudflare_record" "global_wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  content = var.host_ips["directions"]
  type    = "A"
  proxied = false
}
