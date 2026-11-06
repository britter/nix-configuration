# Explicit CNAME delegation for ACME DNS-01 challenge nodes.
#
# Same records as ../inwx/challenge-delegation.tf, kept in parity until the
# Cloudflare zones are decommissioned (Phase 6 of the DNS migration). See
# that file for the rationale: wildcard synthesis at *_acme-challenge nodes
# shadows the TXT challenges of wildcard certificates.

resource "cloudflare_dns_record" "acme_challenge" {
  for_each = var.host_ips
  zone_id  = var.cloudflare_zone_id
  name     = "_acme-challenge.${each.key}"
  content  = "acme.${each.key}.challenge.ritter.family"
  type     = "CNAME"
  proxied  = false
  ttl      = 1
}

resource "cloudflare_dns_record" "acme_challenge_apex" {
  zone_id = var.cloudflare_zone_id
  name    = "_acme-challenge"
  content = "acme.apex.challenge.ritter.family"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}
