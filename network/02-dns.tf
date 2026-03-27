resource "unifi_dns_record" "directions" {
  name        = "directions.ritter.family"
  record_type = "A"
  value       = unifi_client.directions.fixed_ip
  ttl         = 60
}

resource "unifi_dns_record" "directions_wildcard" {
  name        = "*.ritter.family"
  record_type = "A"
  value       = unifi_client.directions.fixed_ip
  ttl         = 60
}

resource "unifi_dns_record" "srv_prod_2" {
  name        = "srv-prod-2.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_2_new.fixed_ip
  ttl         = 60
}

resource "unifi_dns_record" "srv_prod_2_wildcard" {
  name        = "*.srv-prod-2.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_2_new.fixed_ip
  ttl         = 60
}

resource "unifi_dns_record" "srv_prod_3" {
  name        = "srv-prod-3.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_3_new.fixed_ip
  ttl         = 60
}

resource "unifi_dns_record" "srv_prod_3_wildcard" {
  name        = "*.srv-prod-3.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_3_new.fixed_ip
  ttl         = 60
}

resource "unifi_dns_record" "srv_test_2" {
  name        = "srv-test-2.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_test_2.fixed_ip
  ttl         = 60
}

resource "unifi_dns_record" "srv_test_2_wildcard" {
  name        = "*.srv-test-2.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_test_2.fixed_ip
  ttl         = 60
}

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
