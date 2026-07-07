variable "cloudflare_zone_id" {
  type = string
}

variable "host_ips" {
  type = map(string)
}


resource "cloudflare_api_token" "acme_tokens" {
  for_each = var.host_ips
  name     = "${each.key} acme token"

  status = "active"

  policies = [
    {
      effect            = "allow"
      permission_groups = [for k, v in data.cloudflare_api_token_permission_groups_list.all.result : { id = v.id } if v.scopes[0] == "com.cloudflare.api.account.zone" && v.name == "DNS Write"]
      resources = jsonencode({
        "com.cloudflare.api.account.zone.${var.cloudflare_zone_id}" = "*"
      })
    }
  ]
}

output "acme_tokens" {
  value     = { for k, t in cloudflare_api_token.acme_tokens : k => t.value }
  sensitive = true
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
