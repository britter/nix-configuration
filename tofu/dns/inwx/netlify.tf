# Web records for the static website (Netlify site "britter-dev", built from
# github.com/britter/website). Ported from the britter/domains repository.
#
# The apex records were CNAMEs in Cloudflare (flattened to A records on the
# wire). INWX rejects CNAMEs at the apex, so they become ALIAS records with
# the same target — INWX synthesises A/AAAA answers like Cloudflare
# flattening does. Note: ALIAS limits DNSSEC on the zone; this migration
# deliberately does not enable DNSSEC.

resource "inwx_nameserver_record" "britter_dev_apex" {
  domain  = "britter.dev"
  name    = ""
  type    = "ALIAS"
  content = "apex-loadbalancer.netlify.com"
  ttl     = 300
}

resource "inwx_nameserver_record" "britter_dev_www" {
  domain  = "britter.dev"
  name    = "www"
  type    = "CNAME"
  content = "britter-dev.netlify.app"
  ttl     = 300
}

resource "inwx_nameserver_record" "benediktritter_de_apex" {
  domain  = "benediktritter.de"
  name    = ""
  type    = "ALIAS"
  content = "apex-loadbalancer.netlify.com"
  ttl     = 300
}

resource "inwx_nameserver_record" "benediktritter_de_www" {
  domain  = "benediktritter.de"
  name    = "www"
  type    = "CNAME"
  content = "britter-dev.netlify.app"
  ttl     = 300
}
