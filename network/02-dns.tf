resource "unifi_dns_record" "srv_prod_2_new" {
  name        = "srv-prod-2-new.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_2_new.fixed_ip
  ttl         = 60
}

resource "unifi_dns_record" "srv_prod_2_new_wildcard" {
  name        = "*.srv-prod-2-new.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_2_new.fixed_ip
  ttl         = 60
}

resource "unifi_dns_record" "srv_prod_3_new" {
  name        = "srv-prod-3-new.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_3_new.fixed_ip
  ttl         = 60
}

resource "unifi_dns_record" "srv_prod_3_new_wildcard" {
  name        = "*.srv-prod-3-new.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_3_new.fixed_ip
  ttl         = 60
}
