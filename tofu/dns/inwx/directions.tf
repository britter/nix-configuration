# Global wildcard for the edge proxy: every name under ritter.family that is
# not covered by a per-host record resolves to the directions host.
resource "inwx_nameserver_record" "global_wildcard" {
  domain  = inwx_nameserver.zone["ritter.family"].domain
  name    = "*.${inwx_nameserver.zone["ritter.family"].domain}"
  type    = "A"
  content = var.host_ips["directions"]
  ttl     = local.ttl
}
