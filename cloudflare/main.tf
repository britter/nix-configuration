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

resource "cloudflare_api_token" "acme_tokens" {
  for_each = var.host_ips
  name     = "${each.key} acme token"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.${var.cloudflare_zone_id}" = "*"
    }
  }
}

output "acme_tokens" {
  value     = { for k, t in cloudflare_api_token.acme_tokens : k => t.value }
  sensitive = true
}
