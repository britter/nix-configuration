## Unbiquiti Network Definitions

OpenTofu module to manage network resources controlled by Unifi Dream Machine Pro.

### Importing clients

- Look up the clients Mac address in UDM web UI
- Create a `unifi_client` resource with using that Mac address
- Import the client via `tofu import unifi_client.client_resource_name "<mac-address>"`
- Configure name, fixed_ip, local_dns_record, etc. if desired
- `tofu plan` && `tofu apply`

### Provider issues

It looks like the provider is quite brittle in version 0.41.25.
If tofu operations crash, make sure you're using the latest provider and latest Unifi OS on the UDM.
Even small miss matches between provider version and Unifi OS seem to be causing crashes.

Changing client configurations seems to cause crashes as well.
If applying a client change causes the provider to crash, remove the client resource via `tofu state rm unifi_client.client_resource_name` then import the client resource again, as described above.
