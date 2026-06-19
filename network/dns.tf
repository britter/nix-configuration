resource "unifi_dns_record" "directions" {
  name        = "directions.ritter.family"
  record_type = "A"
  value       = unifi_client.directions.fixed_ip
  ttl         = "1h"
}

resource "unifi_dns_record" "directions_wildcard" {
  name        = "*.ritter.family"
  record_type = "A"
  value       = unifi_client.directions.fixed_ip
  ttl         = "1h"
}

resource "unifi_dns_record" "srv_prod_2" {
  name        = "srv-prod-2.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_2_new.fixed_ip
  ttl         = "1h"
}

resource "unifi_dns_record" "srv_prod_2_wildcard" {
  name        = "*.srv-prod-2.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_2_new.fixed_ip
  ttl         = "1h"
}

resource "unifi_dns_record" "srv_prod_3" {
  name        = "srv-prod-3.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_3_new.fixed_ip
  ttl         = "1h"
}

resource "unifi_dns_record" "srv_prod_3_wildcard" {
  name        = "*.srv-prod-3.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_3_new.fixed_ip
  ttl         = "1h"
}

resource "unifi_dns_record" "srv_prod_4" {
  name        = "srv-prod-4.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_4.fixed_ip
  ttl         = "1h"
}

resource "unifi_dns_record" "srv_prod_4_wildcard" {
  name        = "*.srv-prod-4.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_4.fixed_ip
  ttl         = "1h"
}

resource "unifi_dns_record" "srv_prod_5" {
  name        = "srv-prod-5.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_5.fixed_ip
  ttl         = "1h"
}

resource "unifi_dns_record" "srv_prod_5_wildcard" {
  name        = "*.srv-prod-5.ritter.family"
  record_type = "A"
  value       = unifi_client.srv_prod_5.fixed_ip
  ttl         = "1h"
}
resource "unifi_dns_record" "true_nas" {
  name        = "storage.ritter.family"
  record_type = "A"
  value       = unifi_client.true_nas.fixed_ip
  ttl         = "1h"
}
