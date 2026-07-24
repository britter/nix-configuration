resource "unifi_firewall_policy" "trusted_to_homelab_networks_ping" {
  name                 = "Allow pinging from Trusted"
  action               = "ALLOW"
  protocol             = "icmp"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.trusted.id]
  }

  destination = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids = [
      unifi_network.homelab.id,
      unifi_network.management.id,
      unifi_network.smart_home.id,
      unifi_network.servers.id
    ]
    port_matching_type = "ANY"
  }
}

resource "unifi_firewall_policy" "trusted_to_homelab_networks_https" {
  name                 = "Allow HTTPS from Trusted"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.trusted.id]
  }

  destination = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids = [
      unifi_network.homelab.id,
      unifi_network.servers.id,
      unifi_network.kvms.id,
      unifi_network.management.id
    ]
    port              = "443"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "trusted_to_homelab_dns" {
  name                 = "Allow DNS from Trusted to Homelab"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.trusted.id]
  }

  destination = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.homelab.id]
    port              = "53"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "trusted_to_homelab_dns_tls" {
  name                 = "Allow DNS-TLS from Trusted to Homelab"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.trusted.id]
  }

  destination = {
    zone_id           = data.unifi_firewall_zone.internal.id
    matching_target   = "NETWORK"
    network_ids       = [unifi_network.homelab.id]
    port              = "853"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "trusted_to_networks_ssh" {
  name                 = "Allow SSH from Trusted"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.trusted.id]
  }

  destination = {
    zone_id           = data.unifi_firewall_zone.internal.id
    matching_target   = "NETWORK"
    network_ids = [
      unifi_network.homelab.id,
      unifi_network.management.id,
      unifi_network.smart_home.id,
      unifi_network.servers.id
    ]
    port              = "22"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "trusted_to_homelab_networks_http" {
  name                 = "Allow HTTP from Trusted"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.trusted.id]
  }

  destination = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids = [
      unifi_network.homelab.id,
      unifi_network.servers.id,
      unifi_network.kvms.id,
      unifi_network.management.id
    ]
    port_matching_type = "SPECIFIC"
  }
}
