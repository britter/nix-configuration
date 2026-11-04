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

  # INWX minimum, matches Cloudflare's "auto" TTL
  ttl = 300
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
#
# Records take their `domain` from the zone resource rather than repeating
# the name; that reference also makes every record wait for its zone to be
# provisioned — records hitting the INWX API before their zone exists fail
# with 2303 (Object does not exist).
resource "inwx_nameserver_record" "host" {
  for_each = var.host_ips
  domain   = inwx_nameserver.zone["ritter.family"].domain
  name     = "${each.key}.${inwx_nameserver.zone["ritter.family"].domain}"
  type     = "A"
  content  = each.value
  ttl      = local.ttl
}

# Wildcard per host so every vhost behind the proxy resolves without its own
# record, e.g. *.srv-prod-1.ritter.family -> srv-prod-1.ritter.family.
resource "inwx_nameserver_record" "host_wildcard" {
  for_each = inwx_nameserver_record.host
  domain   = inwx_nameserver.zone["ritter.family"].domain
  name     = "*.${each.key}.${inwx_nameserver.zone["ritter.family"].domain}"
  type     = "CNAME"
  content  = "${each.key}.ritter.family"
  ttl      = local.ttl
}
