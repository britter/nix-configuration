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
    networks_ids = [
      unifi_network.homelab.id,
      unifi_network.management.id,
      unifi_network.smart_home.id,
      unifi_network.servers.id
    ]
    port_matching_type = "ANY"
  }
}
