# External DNS configuration

[Cloudflare](https://cloudflare.com) is use to manage external DNS records.
DNS records point to [Tailscale](https://tailscale.com) IP addresses.
Tailscale provider is used to retrieved IP addresses of known devices from the Tailscale API.
Using that data DNS entries are automatically created via Cloudflare.

The interplay between these public records and the local DNS overrides
(AdGuard Home) is described in [docs/split-dns.md](../../docs/split-dns.md).

The [INWX](https://inwx.de) provider is already configured (automation-account
credentials from `secrets.json`, keys `inwx_username` / `inwx_password`) in
preparation for the DNS migration; it does not manage any resources yet.
See [docs/plans/cloudflare-to-inwx-dns-migration.md](../../docs/plans/cloudflare-to-inwx-dns-migration.md).

## Known issues

### Tailscale data refresh times out

This is because Tailscale API tokens are only valid for at most 90 days, so every once in a while the API token is invalided making all requests fail.
To fix this go to tailscale.com > Settings > Personal Settings > Keys and generate a new API token.
Put the new token in `./secrets.json`.
