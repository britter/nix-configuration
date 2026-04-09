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

resource "unifi_network" "management" {
  name               = "Management"
  subnet             = "192.168.10.1/24"
  vlan               = 10
  setting_preference = "manual"
  auto_scale         = false
  network_isolation  = true
  multicast_dns      = false

  dhcp_server = {
    enabled           = true
    conflict_checking = true
    gateway_enabled   = false

    dns_enabled = false

    leasetime           = 86400
    ntp_enabled         = false
    start               = "192.168.10.6"
    stop                = "192.168.10.254"
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

resource "unifi_network" "smart_home" {
  name               = "Smart Home"
  subnet             = "192.168.20.1/24"
  vlan               = 20
  setting_preference = "manual"
  auto_scale         = false
  network_isolation  = true

  dhcp_server = {
    enabled           = true
    conflict_checking = true
    gateway_enabled   = false

    dns_enabled = false

    leasetime           = 86400
    ntp_enabled         = false
    start               = "192.168.20.6"
    stop                = "192.168.20.254"
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

resource "unifi_network" "servers" {
  name               = "Servers"
  subnet             = "192.168.30.1/24"
  vlan               = 30
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
    start               = "192.168.30.6"
    stop                = "192.168.30.254"
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

resource "unifi_network" "kvms" {
  name               = "KVMs"
  subnet             = "192.168.40.1/24"
  vlan               = 40
  setting_preference = "manual"
  auto_scale         = false
  network_isolation  = true
  internet_access    = false

  dhcp_server = {
    enabled           = true
    conflict_checking = true
    gateway_enabled   = false

    dns_enabled = false

    leasetime           = 86400
    ntp_enabled         = false
    start               = "192.168.40.6"
    stop                = "192.168.40.254"
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

resource "unifi_network" "guests" {
  name               = "Guest"
  subnet             = "192.168.60.1/24"
  vlan               = 60
  setting_preference = "manual"
  auto_scale         = false
  network_isolation  = true
  multicast_dns      = false

  dhcp_server = {
    enabled           = true
    conflict_checking = true
    gateway_enabled   = false

    dns_enabled = false

    leasetime           = 86400
    ntp_enabled         = false
    start               = "192.168.60.6"
    stop                = "192.168.60.254"
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
