variable "cloudflare_zone_id" {
  type = string
}

variable "host_ips" {
  type = map(string)
}

resource "cloudflare_record" "host" {
  for_each = var.host_ips
  zone_id  = var.cloudflare_zone_id
  name     = each.key
  content  = each.value
  type     = "A"
  proxied  = false
}

resource "cloudflare_record" "host_wildcard" {
  for_each = cloudflare_record.host
  zone_id  = var.cloudflare_zone_id
  name     = "*.${each.value.name}"
  content  = "${each.value.name}.ritter.family"
  type     = "CNAME"
  proxied  = false
}

