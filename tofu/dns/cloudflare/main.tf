variable "cloudflare_zone_id" {
  type = string
}

variable "host_ips" {
  type = map(string)
}

resource "cloudflare_dns_record" "host" {
  for_each = var.host_ips
  zone_id  = var.cloudflare_zone_id
  name     = each.key
  content  = each.value
  type     = "A"
  proxied  = false
  ttl      = 1
}

resource "cloudflare_dns_record" "host_wildcard" {
  for_each = cloudflare_dns_record.host
  zone_id  = var.cloudflare_zone_id
  name     = "*.${each.value.name}"
  content  = each.value.name
  type     = "CNAME"
  proxied  = false
  ttl      = 1
}
