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
    port               = "443"
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
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.homelab.id]
    port               = "53"
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
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.homelab.id]
    port               = "853"
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
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids = [
      unifi_network.homelab.id,
      unifi_network.management.id,
      unifi_network.smart_home.id,
      unifi_network.servers.id
    ]
    port               = "22"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "trusted_to_kvms_udp" {
  name                 = "Allow UDP from Trusted to KVMs"
  action               = "ALLOW"
  protocol             = "udp"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true
  description          = "Required for JetKVM's WebRTC video streaming."

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.trusted.id]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.kvms.id]
    port               = "1024-65535"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "trusted_to_home_assistant" {
  name                 = "Allow Traffic from Trusted to Home Assistant"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true
  description          = "Required to access home assistant Web UI"

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.trusted.id]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.smart_home.id]
    port               = "8123"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "home_assistant_to_yeelights" {
  name                 = "Allow Home Assistant to Control Yeelights in NoT"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true
  description          = "Allow TCP on port 55443"

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.smart_home.id]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.not.id]
    port               = "55443"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "homelab_servers_to_home_assistant" {
  name                 = "Allow Poxying of Home Assistant"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true
  description          = "Default port for HA web UI is 8123"

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids = [
      unifi_network.homelab.id,
      unifi_network.servers.id
    ]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.smart_home.id]
    port               = "8123"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "trusted_to_management_pve" {
  name                 = "Allow PVE Management from Trusted"
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
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.management.id]
    port               = "8006"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "servers_to_homelab_https" {
  name                 = "Allow HTTPS from Servers to Homelab"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true
  description          = "Required during setup of new proxmox server"

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.servers.id]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.homelab.id]
    port               = "443"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "servers_to_homelab_dns" {
  name                 = "Allow Servers to access DNS in Homelab"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.servers.id]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.homelab.id]
    port               = "53"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "servers_to_homelab_dns_tls" {
  name                 = "Allow Servers to access DNS-TLS in Homelab"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.servers.id]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.homelab.id]
    port               = "853"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "trusted_to_not_print" {
  name                 = "Allow Trusted to Print"
  action               = "ALLOW"
  protocol             = "tcp_udp"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true
  description          = "Allows Port 9100 and 631 which is required for printing on HP Printers"

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.trusted.id]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.not.id]
    port               = "631,9100"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "homelab_to_servers_http" {
  name                 = "Allow HTTP form Homelab to servers"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.homelab.id]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.servers.id]
    port               = "80"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "homelab_to_servers_https" {
  name                 = "Allow HTTPS from Homelab to servers"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.homelab.id]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.servers.id]
    port               = "443"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "servers_to_management_nfs" {
  name                 = "Allow NFS mount from Servers to Management"
  action               = "ALLOW"
  protocol             = "all"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "NETWORK"
    network_ids     = [unifi_network.servers.id]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.management.id]
    port               = "2049"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "directions_to_pve" {
  name                 = "Allow HTTPS from directions to PVE"
  action               = "ALLOW"
  protocol             = "tcp"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "CLIENT"
    client_macs     = [unifi_client.directions.mac]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "IP"
    ips                = [unifi_client.pve.fixed_ip]
    port               = "8006"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "directions_to_truenas" {
  name                 = "Allow HTTP/HTTPS from directions to TrueNAS"
  action               = "ALLOW"
  protocol             = "tcp"
  ip_version           = "BOTH"
  logging              = false
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "CLIENT"
    client_macs     = [unifi_client.directions.mac]
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "IP"
    ips                = [unifi_client.true_nas.fixed_ip]
    port               = "80,443"
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
