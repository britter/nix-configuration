# Split DNS for `ritter.family`

All homelab services use names under `ritter.family`, but **the same name
resolves to different addresses depending on where the asking client is**:

```
                            ┌────────────────────────────────┐
   Home LAN client          │ UniFi gateway (UDM Pro)        │
   ────────────────────►    │ unifi_dns_record (LAN zone)    │──► LAN IPs
        DHCP-resolver       │ tofu/network/dns.tf            │    (unifi_client.fixed_ip)
                            └──────────────┬─────────────────┘
                                           │ upstream
                                           ▼
                            ┌────────────────────────────────┐
   Away, on Tailscale       │ Public DNS (Cloudflare,        │
   ────────────────────►    │ later INWX)                    │──► Tailscale IPs
                            │ tofu/dns/cloudflare/           │    100.x.y.z
                            └────────────────────────────────┘
```

## Public zone: a tailnet service directory

The public records in `tofu/dns/cloudflare/` do **not** point at publicly
reachable addresses. They point at **Tailscale IP addresses**, retrieved
from the Tailscale API (`tofu/dns/main.tf` wires
`module.tailscale.device_ips` into the Cloudflare module):

- `<host>.ritter.family` — A record with the host's Tailscale IP.
- `*.<host>.ritter.family` — CNAME to `<host>.ritter.family`, so per-host
  service vhosts (`nextcloud.srv-prod-2.ritter.family`, …) follow their
  host automatically.
- `*.ritter.family` — global wildcard A record to `directions`, covering
  the edge-proxied names (`nextcloud.ritter.family`, `git.ritter.family`,
  …).

Consequences worth knowing:

- **Nothing is reachable from the open internet.** A random scanner or a
  leaked URL resolves a `100.x` CGNAT address that only exists inside the
  tailnet. The public DNS zone is effectively a service directory for
  tailnet members — the "public" services are public to Tailscale, not to
  the world.
- **TLS certificates are unaffected by any of this.** They are issued via
  ACME DNS-01, which never touches the A records, so the same valid
  certificate is served on both resolution paths.
- The Tailscale API token used by `tofu` expires every ~90 days; see the
  known issues in `tofu/dns/README.md`.

## Local zone: UniFi gateway DNS records

Inside the home network, the same names resolve to LAN addresses. This is
not AdGuard rewriting and not split-horizon magic on a server — it is the
**UniFi Dream Machine Pro serving DNS records for the LAN**, managed
declaratively in `tofu/network/dns.tf`:

- `unifi_dns_record` resources define the local zone: per-host A records
  (`srv-prod-N.ritter.family`), per-host wildcards
  (`*.srv-prod-N.ritter.family`), the global wildcard
  (`*.ritter.family` → directions), plus devices without a public record
  (`storage.ritter.family` for TrueNAS).
- Values are `unifi_client.<host>.fixed_ip` — the fixed IPs assigned to
  clients in `clients.tf`, so a device's DNS name and its DHCP reservation
  are the same resource.
- AdGuard Home (on directions, module `modules/nixos/adguard.nix`) does
  **content filtering only** for LAN clients; for `ritter.family` queries
  it is transparent — it forwards upstream to the gateway, which answers
  from its `unifi_dns_record`s.

Home-LAN traffic to any homelab service therefore takes the direct path
into the `192.168.30.0/24` segment — no Tailscale detour, no hairpin.

## Sources of truth for a name

A single service name is defined in up to four places, with two
independent IP value sets:

| Place | Managed by | Content |
|---|---|---|
| `tofu/network/dns.tf` + `clients.tf` | git (OpenTofu) | Local zone: LAN IPs (`unifi_client.fixed_ip`), per-host + global wildcards |
| `tofu/dns/` | git (OpenTofu) | Public zone: Tailscale IPs from the Tailscale API, mirroring the same record structure |
| `modules/generic/home-lab.nix` | git (Nix) | LAN IPs duplicated for Nix config — proxy targets (`https-proxy`), WOPISrc allowlists, ssh config |
| AdGuard Home | `modules/nixos/adguard.nix` + UI state | Filtering/blocklists only; no `ritter.family` answers |

Note the duplication: LAN IPs exist both as `unifi_client.fixed_ip`
(`tofu/network/`) and in `modules/generic/home-lab.nix`. When a host's
address changes, both must be updated.

## Resolution paths in practice

| Client | Answering resolver | `nextcloud.ritter.family` resolves to | Path |
|---|---|---|---|
| Home LAN | UniFi gateway (directly or via AdGuard upstream) | `192.168.30.6` (directions, edge) | LAN → edge → backend over LAN |
| Home LAN, direct per-host name | UniFi gateway | backend host LAN IP, e.g. `192.168.30.12` | LAN direct |
| Away, Tailscale on | Public DNS | directions' Tailscale IP | tailnet → edge → backend |
| Away, Tailscale on, per-host name | Public DNS | backend host's Tailscale IP | tailnet direct to backend |
| Away, no Tailscale | Public DNS | Tailscale CGNAT address | **unreachable — by design** |

## Interaction with the INWX migration

`docs/plans/archive/2026-11-11-cloudflare-to-inwx-dns-migration.md` moves the public zone
(Cloudflare → INWX) and the registrations. This does not touch the split:

- The local zone on the UniFi gateway is name-based and independent of the
  public DNS provider — it survives the change untouched.
- The INWX zone port in `tofu/dns/` must keep pointing at the Tailscale
  IPs exactly as the Cloudflare zone does today.

## TODOs

- [ ] Consider generating `modules/generic/home-lab.nix` LAN IPs from the
      `unifi_client.fixed_ip` values (or vice versa) so each address has
      one source of truth.
