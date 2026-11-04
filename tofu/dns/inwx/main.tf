variable "host_ips" {
  type = map(string)
}

locals {
  zones = toset([
    "ritter.family",
    "britter.dev",
    "benediktritter.de",
  ])

  inwx_nameservers = [
    "ns.inwx.de",
    "ns2.inwx.de",
    "ns3.inwx.eu",
  ]
}

# One zone per domain on INWX's anycast nameservers. While the domains still
# delegate to Cloudflare these zones are inert.
resource "inwx_nameserver" "zone" {
  for_each    = local.zones
  domain      = each.value
  type        = "MASTER"
  nameservers = local.inwx_nameservers
  # Otherwise INWX stores its default SOA mailbox (hostmaster@inwx.de) and
  # every plan shows a change that tries to recreate the zone.
  soa_mail = "hostmaster@inwx.de"
}

# A record per Tailscale device, e.g. srv-prod-1.ritter.family.
resource "inwx_nameserver_record" "host" {
  for_each = var.host_ips
  domain   = "ritter.family"
  name     = each.key
  type     = "A"
  content  = each.value
  ttl      = 300
}

# Wildcard per host so every vhost behind the proxy resolves without its own
# record, e.g. *.srv-prod-1.ritter.family -> srv-prod-1.ritter.family.
resource "inwx_nameserver_record" "host_wildcard" {
  for_each = inwx_nameserver_record.host
  domain   = "ritter.family"
  name     = "*.${each.key}"
  type     = "CNAME"
  content  = "${each.key}.ritter.family"
  ttl      = 300
}
