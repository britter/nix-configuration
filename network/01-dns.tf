resource "unifi_dns_record" "srv_prod_2_new" {
  name        = "srv-prod-2-new.ritter.family"
  record_type = "A"
  value       = "192.168.30.12"
  ttl         = 60
}

resource "unifi_dns_record" "srv_prod_2_new_wildcard" {
  name        = "*.srv-prod-2-new.ritter.family"
  record_type = "A"
  value       = "192.168.30.12"
  ttl         = 60
}

resource "unifi_dns_record" "srv_prod_3_new" {
  name        = "srv-prod-3-new.ritter.family"
  record_type = "A"
  value       = "192.168.30.13"
  ttl         = 60
}

resource "unifi_dns_record" "srv_prod_3_new_wildcard" {
  name        = "*.srv-prod-3-new.ritter.family"
  record_type = "A"
  value       = "192.168.30.13"
  ttl         = 60
}
