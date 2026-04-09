resource "unifi_network" "default" {
  name               = "Default"
  subnet             = "192.168.1.1/24"
  setting_preference = "manual"

  dhcp_server = {
    enabled           = true
    conflict_checking = true
    gateway_enabled   = false

    dns_enabled = true
    dns_servers = [
      unifi_client.directions.fixed_ip
    ]

    leasetime           = 86400
    ntp_enabled         = false
    start               = "192.168.1.6"
    stop                = "192.168.1.254"
    time_offset_enabled = false

    boot = {
      enabled = false
      server  = ""
    }

    wins = {
      enabled = false
    }
  }
}

resource "unifi_network" "trusted" {
  name               = "Trusted"
  subnet             = "192.168.50.1/24"
  vlan               = 50
  setting_preference = "manual"
  auto_scale         = false
  network_isolation  = true

  dhcp_server = {
    enabled           = true
    conflict_checking = true
    gateway_enabled   = false

    dns_enabled = true
    dns_servers = [
      unifi_client.directions.fixed_ip
    ]

    leasetime           = 86400
    ntp_enabled         = false
    start               = "192.168.50.6"
    stop                = "192.168.50.254"
    time_offset_enabled = false

    boot = {
      enabled = false
      server  = ""
    }

    wins = {
      enabled = false
    }
  }
}
