# Global wildcard for the edge proxy: every name under ritter.family that is
# not covered by a per-host record resolves to the directions host.
resource "inwx_nameserver_record" "global_wildcard" {
  domain  = "ritter.family"
  name    = "*"
  type    = "A"
  content = var.host_ips["directions"]
  ttl     = 300
}
