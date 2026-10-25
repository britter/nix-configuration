resource "unifi_client" "directions" {
  name     = "directions"
  mac      = "d8:3a:dd:72:2a:26"
  fixed_ip = "192.168.30.6"
}

resource "unifi_client" "pve" {
  name     = "pve"
  mac      = "a8:2b:dd:ce:bf:b5"
  fixed_ip = "192.168.10.10"
}

resource "unifi_client" "homeassistant" {
  name     = "homeassistant"
  mac      = "20:f8:3b:01:fa:16"
  fixed_ip = "192.168.20.234"
}

resource "unifi_client" "srv_prod_1" {
  name     = "srv-prod-1"
  mac      = "bc:24:11:9f:9a:3c"
  fixed_ip = "192.168.30.11"
}

resource "unifi_client" "srv_prod_2_new" {
  name     = "srv-prod-2"
  mac      = "bc:24:11:82:d1:0d"
  fixed_ip = "192.168.30.12"
}

resource "unifi_client" "srv_prod_3_new" {
  name     = "srv-prod-3"
  mac      = "bc:24:11:b5:f0:5b"
  fixed_ip = "192.168.30.13"
}

resource "unifi_client" "srv_prod_4" {
  name     = "srv-prod-4"
  mac      = "bc:24:11:3e:b6:64"
  fixed_ip = "192.168.30.14"
}

resource "unifi_client" "srv_prod_5" {
  name     = "srv-prod-5"
  mac      = "bc:24:11:64:0b:a7"
  fixed_ip = "192.168.30.15"
}

resource "unifi_client" "srv_prod_6" {
  name     = "srv-prod-6"
  mac      = "bc:24:11:3b:29:ac"
  fixed_ip = "192.168.30.16"
}

resource "unifi_client" "true_nas" {
  name     = "TrueNAS"
  mac      = "00:d0:b4:02:55:db"
  fixed_ip = "192.168.10.20"
}
