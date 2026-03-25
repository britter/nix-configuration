# External DNS configuration

[Cloudflare](https://cloudflare.com) is use to manage external DNS records.
DNS records point to [Tailscale](https://tailscale.com) IP addresses.
Tailscale provider is used to retrieved IP addresses of known devices from the Tailscale API.
Using that data DNS entries are automatically created via Cloudflare.

## Known issues

### Tailscale data refresh times out

This is because Tailscale API tokens are only valid for at most 90 days, so every once in a while the API token is invalided making all requests fail.
To fix this go to tailscale.com > Settings > Personal Settings > Keys and generate a new API token.
Put the new token in `./secrets.json`.
