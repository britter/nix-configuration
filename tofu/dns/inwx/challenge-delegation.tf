# Explicit CNAME delegation for ACME DNS-01 challenge nodes.
#
# A wildcard cert for *.X.ritter.family requires its TXT challenge at
# _acme-challenge.X.ritter.family — a name exactly one label deep, the same
# depth the wildcard records above are defined at. DNS wildcard synthesis
# therefore owns the challenge node, and with an odd type mismatch: the
# synthetic CNAME shadows TXT queries there, lego chases it and writes the
# TXT at the wildcard's own target, and Let's Encrypt's validation through public
# resolvers ends up cache-dependent (observed 2026-11-06, see
# docs/incidents/2026-11-06-untrusted-wildcard-certs.md).
#
# These records fix that by *owning* the challenge node explicitly: an
# explicit record at a node always shadows wildcard synthesis. The CNAME
# targets live two or more labels deep inside the reserved "challenge"
# subtree, which no wildcard record in this zone can ever capture — so the
# challenge chain (LE -> _acme-challenge.<X> -> target -> lego's TXT) is
# deterministic for every resolver. lego follows the CNAME and places the
# TXT at the target; no further ACME configuration is involved.
#
# The "challenge" subtree is reserved for this: do not put service records
# there, they would collide with the TXT records lego writes and removes.
# The apex wildcard cert (*.ritter.family, on directions) needs its own
# delegation, since _acme-challenge.ritter.family is captured by the
# global wildcard.

resource "inwx_nameserver_record" "acme_challenge" {
  for_each = var.host_ips
  domain   = inwx_nameserver.zone["ritter.family"].domain
  name     = "_acme-challenge.${each.key}.${inwx_nameserver.zone["ritter.family"].domain}"
  type     = "CNAME"
  content  = "acme.${each.key}.challenge.${inwx_nameserver.zone["ritter.family"].domain}"
  ttl      = local.ttl
}

resource "inwx_nameserver_record" "acme_challenge_apex" {
  domain  = inwx_nameserver.zone["ritter.family"].domain
  name    = "_acme-challenge.${inwx_nameserver.zone["ritter.family"].domain}"
  type    = "CNAME"
  content = "acme.apex.challenge.${inwx_nameserver.zone["ritter.family"].domain}"
  ttl     = local.ttl
}
