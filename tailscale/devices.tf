data "tailscale_device" "devices" {
  for_each = toset(local.devices)
  name     = "${each.key}.${local.tailnet}"
  wait_for = "60s"
}

output "device_ips" {
  value = {
    for k, v in data.tailscale_device.devices : k => v.addresses[0]
  }
}

