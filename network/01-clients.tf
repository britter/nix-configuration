resource "unifi_client" "homeassistant" {
  name     = "homeassistant"
  mac      = "20:f8:3b:01:fa:16"
  fixed_ip = "192.168.20.234"
}

resource "unifi_client" "srv_prod_2" {
  name     = "srv-prod-2"
  mac      = "1a:d8:70:16:71:8a"
  fixed_ip = "192.168.5.12"
}

resource "unifi_client" "srv_prod_3" {
  name     = "srv-prod-3"
  mac      = "6e:b0:e4:76:23:02"
  fixed_ip = "192.168.5.13"
}

resource "unifi_client" "srv_test_2" {
  name     = "srv-test-2"
  mac      = "1e:1e:b9:3a:7a:56"
  fixed_ip = "192.168.5.21"
}

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
