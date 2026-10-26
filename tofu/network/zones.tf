data "unifi_firewall_zone" "internal" {
  name = "Internal"
}

data "unifi_firewall_zone" "external" {
  name = "External"
}

data "unifi_firewall_zone" "gateway" {
  name = "Gateway"
}

data "unifi_firewall_zone" "vpn" {
  name = "Vpn"
}

data "unifi_firewall_zone" "hotspot" {
  name = "Hotspot"
}

data "unifi_firewall_zone" "dmz" {
  name = "Dmz"
}
