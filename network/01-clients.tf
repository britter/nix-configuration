resource "unifi_client" "srv_prod_2_new" {
  name     = "srv-prod-2-new"
  mac      = "bc:24:11:82:d1:0d"
  fixed_ip = "192.168.30.12"
}

resource "unifi_client" "srv_prod_3_new" {
  name     = "srv-prod-3-new"
  mac      = "bc:24:11:b5:f0:5b"
  fixed_ip = "192.168.30.13"
}
