# Plan: Migrate DNS from Cloudflare to INWX

**Status:** ⏳ Draft — not started
**Created:** 2026-11-03

## Goal

Move DNS hosting for all three domains from Cloudflare to INWX, and move
domain registrations to INWX as well — so that ACME DNS-01 challenges for the
homelab certificates are answered against INWX instead of Cloudflare.

The reverse-proxy stack (nginx, `services.https-proxy`, `security.acme`)
stays as it is. Only the ACME *provider* configuration changes; the
nginx-vs-Caddy-vs-Traefik question is explicitly out of scope. All cert
issuance continues to run through `security.acme` (lego) exactly as today —
lego has shipped a native INWX DNS provider since v2.0.0, so no component
other than the `security.acme` defaults block changes.

## Current state (verified via RDAP/whois, 2026-11-03)

| Domain | Registrar | DNS host | Expires | DNSSEC | Transfer lock |
|---|---|---|---|---|---|
| `ritter.family` | Cloudflare, Inc | Cloudflare | **2027-06-28** | No DS record | `clientTransferProhibited` |
| `britter.dev` | Cloudflare, Inc | Cloudflare | **2026-12-21** ⚠️ | Zone signed, but no DS published | `clientTransferProhibited` |
| `benediktritter.de` | Hosting Europe | Cloudflare | not visible via RDAP (.de has no standard RDAP) — check in the Hosting Europe panel | check via DENIC whois | check in panel |

Notes on the current state:

- **The renewal-urgency assumption is only half true.** RDAP shows
  `britter.dev` expiring 2026-12-21 (≈ 7 weeks out — this drives the
  schedule), but `ritter.family` expires 2027-06-28, roughly eight months
  away. Worth double-checking the Cloudflare billing dashboard in case
  RDAP reflects a recently renewed term, but the plan proceeds on the
  RDAP data: `britter.dev` is pressing, `ritter.family` is not.
- Both Cloudflare-registered domains show `last changed` more than 60 days
  ago (`ritter.family`: 2026-08-12, `britter.dev`: 2025-11-26), so the
  ICANN 60-day transfer lock after a registrant change does not apply.
- `britter.dev` has zone signing enabled without a published DS record —
  an incomplete DNSSEC state. Nothing validates against it today. This
  plan does **not** introduce DNSSEC; see Phase 0 for the recommendation
  to switch signing off first.
- DNS records are managed in `tofu/dns/cloudflare/` (OpenTofu): `main.tf`,
  `directions.tf` (the `*.ritter.family` and `*.srv-prod-N.ritter.family`
  wildcards the proxy stack depends on), and `email.tf` (mail records —
  SPF/DKIM/DMARC must be carried over exactly; see Phase 1 verification).

## TLD support and pricing at INWX (checked 2026-11-03)

All three TLDs can be registered at INWX.

| TLD | Available at INWX | Transfer price | Renewal price | Transfer adds a year? |
|---|---|---|---|---|
| `.family` | ✅ (own TLD page; 192 `.family` domains under INWX per ICANN June 2026 report) | ≈ $53–62 | ≈ $53–62 | Yes — gTLD, transfer includes +1 year registration |
| `.dev` | ✅ (own TLD page; 2,446 `.dev` domains at INWX) | ≈ $20 | ≈ $20 | Yes — gTLD |
| `.de` | ✅ (INWX is a German registrar; .de is a core TLD for them) | small "provider switch" fee | standard .de renewal | No — .de transfers do not add a registration year |

Prices are indicative (converted from INWX's price list and price
aggregators, Nov 2026); confirm against
`https://www.inwx.de/en/domain/pricelist` before starting. Two honest
caveats:

- **Renewals get more expensive.** Cloudflare bills at cost; INWX charges
  a margin. Roughly: `.dev` ≈ $12 → $20, `.family` ≈ $26–36 → $53–62,
  per year. That is the price of the provider change — acceptable, but
  decide it consciously. The `.family` renewal delta is the largest.
- `.family` and `.dev` transfers **include one registration year**, billed
  at the transfer price. For `britter.dev` this conveniently *is* the
  pending renewal — transferring before 2026-12-21 renews the domain at
  the same time. For `ritter.family`, transferring early converts the
  June 2027 renewal into a cheaper-to-plan fixed date, but there is no
  urgency benefit.

## Hard constraint that shapes the sequencing

**Domains registered through Cloudflare Registrar cannot use non-Cloudflare
nameservers while they remain registered there.** Cloudflare Registrar
pins NS delegation to Cloudflare. Therefore, for `ritter.family` and
`britter.dev`, the registrar transfer to INWX must happen **before** the
nameserver delegation can point at INWX.

`benediktritter.de` is different: Hosting Europe (as registrar) can change
the nameserver delegation to INWX without a transfer. Transferring the .de
registration to INWX is optional and can happen anytime — it is independent
of where the zone is hosted.

Resulting per-domain order:

- `ritter.family`, `britter.dev`: transfer registrar first → then flip NS.
- `benediktritter.de`: flip NS at Hosting Europe → optionally transfer
  registration later.

## Target state

```
Registrar:      all three domains at INWX
DNS hosting:    all three zones on INWX nameservers
                  (ns.inwx.de, ns2.inwx.de, ns3.inx.wtf)
Zone mgmt:      tofu/dns/inwx/ (OpenTofu, INWX provider)
ACME DNS-01:    security.acme dnsProvider = "inwx",
                credentials from sops (INWX_USERNAME_FILE / INWX_PASSWORD_FILE)
Cloudflare:     zones deleted, API token revoked, sops entries removed
Proxy:          unchanged — nginx + services.https-proxy as today
```

## Phase 0 — Preparation (no user-visible change)

- [ ] Create an INWX account under **inwx.de** (German entity, EUR billing,
      matches where you live). Note that inwx.de / inwx.com / inwx.ch /
      inwx.at are separate entities with different currencies and VAT.
- [ ] Create a dedicated **sub-account** for automation with access to the
      three domains and their nameserver entries — do not use the main
      login for ACME. Enable 2FA on the main account; note the TOTP
      shared secret of the *automation* account, since lego needs it
      (`INWX_SHARED_SECRET`) if 2FA is active there too.
- [ ] Store in sops (per host or via a shared secrets include):
      `acme/inwx-username`, `acme/inwx-password`,
      `acme/inwx-shared-secret` (only if the automation account uses 2FA).
- [ ] Check both Cloudflare-registered domains in the dashboard:
      registrar transfer lock status, auto-renew status, and confirm the
      expiry dates seen via RDAP.
- [ ] Check `benediktritter.de` in the Hosting Europe panel: expiry date,
      DNSSEC status, and whether an authinfo code can be generated there.
- [ ] **DNSSEC:** switch off zone signing for `britter.dev` in Cloudflare
      (it is incomplete anyway — signed zone, no DS in the parent), and
      confirm `ritter.family` has no DNSSEC. Revisit DNSSEC as a separate
      project after the migration; INWX and all three TLDs support it.
- [ ] Add the INWX provider to `tofu` (`inwx/inwx` from the OpenTofu
      registry) with the automation account's credentials via
      `secrets.json`/environment, mirroring how the Cloudflare provider is
      configured today.

## Phase 1 — Replicate all three zones in INWX (non-authoritative)

- [ ] Port `tofu/dns/cloudflare/{main,directions,email}.tf` to an
      `tofu/dns/inwx/` tree, creating the zones and records on INWX's
      nameservers. While the domains still delegate to Cloudflare, these
      zones are inert — creating them changes nothing for users.
- [ ] Every record must be reproduced 1:1, in particular:
      - the apex records for `ritter.family`,
      - the **wildcards** `*.ritter.family` and
        `*.srv-prod-{1..6}.ritter.family` (INWX supports wildcard records),
      - all `email.tf` records: MX, SPF (TXT), DKIM (TXT), DMARC — DKIM
        selector keys must be copied byte-exact or mail signing breaks.
      - any records for `britter.dev` and `benediktritter.de` hosted in
        the same Cloudflare account.
- [ ] Verify zone parity before touching delegation:
      ```sh
      # INWX side (query their NS directly — safe, zone is inert)
      dig @ns.inwx.de ritter.family AXFR          # if AXFR not offered:
      dig @ns.inwx.de <name> <type>               # spot-check each record
      # compare against the live side
      dig @salvador.ns.cloudflare.com <name> <type>
      ```
      A `tofu plan` against the imported state showing no diffs is the
      stronger check — worth doing properly given how much (mail,
      wildcards, per-server names) rides on the zones.

## Phase 2 — Registrar transfers (the time-critical phase)

Start this phase immediately after Phase 1 — `britter.dev` expires
2026-12-21 and gTLD transfers take up to 5 days. Do **not** cut it close:
initiate the transfer by early December at the latest.

- [ ] In Cloudflare (per domain): disable the registrar transfer lock and
      request the auth/EPP code.
- [ ] Initiate the transfer at INWX using the auth code. gTLD transfers
      (`ritter.family`, `britter.dev`) complete in ≤ 5 days; the transfer
      itself renews the domain by one year, which resolves `britter.dev`'s
      pending expiry.
- [ ] `benediktritter.de`: order the **provider switch** (Kconnect/authinfo)
      at INWX, generate the authinfo code in the Hosting Europe panel.
      .de switches typically complete within hours, do not add a
      registration year, and the remaining term carries over.
- [ ] While the domains sit at INWX **before** the NS flip, they still
      delegate to Cloudflare's nameservers — resolution and certificates
      are unaffected. This is the safe parking spot between phases.
- [ ] Watch for transfer-related email from the losing registrars
      (Cloudflare/Hosting Europe may require explicit confirmation).

Rollback for this phase: reject/cancel the pending transfer at INWX, or
re-lock the domain at Cloudflare before it completes. After completion,
the domain lives at INWX; moving it back would be a new transfer.

## Phase 3 — Nameserver delegation flip (the cutover moment)

One domain at a time, lowest-stakes first. Suggested order:
`benediktritter.de` → `britter.dev` → `ritter.family` (the homelab's
primary domain, most traffic, goes last once the procedure is proven).

- [ ] Set the nameservers at the (new) registrar — INWX panel for all
      three now, or Hosting Europe's panel for the .de if its transfer is
      deliberately deferred:
      `ns.inwx.de`, `ns2.inwx.de`, `ns3.inx.wtf`.
- [ ] Propagation of a delegation is TTL-bound (typically hours, up to
      `NS`/`SOA` TTL). Resolvers will serve a mix of old and new NS
      answers during the window — both zones are identical (Phase 1), so
      this is transparent.
- [ ] Verify from the outside:
      ```sh
      dig +trace ritter.family NS
      dig @1.1.1.1 books.ritter.family   # resolves, via new NS
      dig @8.8.8.8 nextcloud.ritter.family
      ```
- [ ] Watch gatus monitors and mail logs for the propagation window.

Rollback for this phase: flip the delegation back at the registrar. The
Cloudflare zones remain intact and in sync until Phase 5, so rollback is
always available within minutes.

## Phase 4 — Flip ACME DNS-01 to INWX (per host, with the comin model)

Each host evaluates and builds its own configuration, so the flip is per
host and independently verifiable. lego's INWX provider is built into
`security.acme`'s lego package — no new dependencies.

- [ ] In `modules/nixos/https-proxy.nix`, change the `security.acme.defaults`
      block:
      ```nix
      dnsProvider = "inwx";
      credentialFiles = {
        "INWX_USERNAME_FILE" = config.sops.secrets."acme/inwx-username".path;
        "INWX_PASSWORD_FILE" = config.sops.secrets."acme/inwx-password".path;
        # only if the automation account has 2FA:
        # "INWX_SHARED_SECRET_FILE" = config.sops.secrets."acme/inwx-shared-secret".path;
      };
      ```
- [ ] Add the INWX credentials to each host's sops secrets
      (`secrets.yaml` per host) alongside the existing Cloudflare token —
      keep the Cloudflare entries until every cert has renewed once.
- [ ] **Validate on the lowest-stakes host first:** srv-prod-5
      (navidrome / `music.ritter.family`). NixOS acme renewal units only
      renew near expiry, so force one re-issuance through INWX:
      ```sh
      # on srv-prod-5, after the switch with new sops secrets:
      systemctl stop acme-music.srv-prod-5.ritter.family.service
      mv /var/lib/acme/music.srv-prod-5.ritter.family \
         /var/lib/acme/music.srv-prod-5.ritter.family.bak
      systemctl start acme-music.srv-prod-5.ritter.family.service
      # watch: journalctl -u acme-music.srv-prod-5.ritter.family -f
      ```
      If the INWX challenge fails, restore the backup directory and
      restart — the old cert keeps serving; nothing client-visible broke.
      Raise `INWX_PROPAGATION_TIMEOUT` via `security.acme.defaults`
      environment if propagation checks time out (default 360 s).
- [ ] Then the edge (directions — highest value, 19 vhosts sharing the
      pattern), then the remaining srv-prod hosts one at a time. Each
      host: switch → force one renewal → verify cert issuer via
      `openssl s_client -connect <host>:443 ... | openssl x509 -noout -text`.
- [ ] srv-prod-2's Nextcloud nginx vhost uses `useACMEHost` from the same
      defaults — it flips along with everything else on that host; no
      separate handling needed.

## Phase 5 — Decommission Cloudflare

Only once **every** certificate on every host has renewed at least once
through INWX (check `/var/lib/acme/*/account*` or cert issuer), and the
gatus monitors have been green across a full cert cycle:

- [ ] Delete the three zones from the Cloudflare account.
- [ ] Revoke and delete the `acme/cloudflare-dns-api-token` sops entries
      everywhere; remove the credentialFiles line from
      `modules/nixos/https-proxy.nix`.
- [ ] Remove `tofu/dns/cloudflare/` (after confirming nothing else uses
      that provider/state) and the Cloudflare provider block.
- [ ] Confirm INWX auto-renew is enabled for all three domains, payment
      method on file, and expiry dates transferred/imported correctly
      (INWX imports the remaining registration term on transfer).

## Timeline

| When | What |
|---|---|
| Week of 2026-11-09 | Phases 0–1: account, tofu port, zones replicated and verified |
| Week of 2026-11-16 | Phase 2: initiate all three transfers (britter.dev deadline buffer: transfer must complete before 2026-12-21; ≤ 5 days once initiated) |
| Late Nov 2026 | Phase 3: NS flips, one domain at a time |
| Early Dec 2026 | Phase 4: ACME flip across hosts, srv-prod-5 pilot → directions → rest |
| ≥ one renewal cycle later | Phase 5: Cloudflare decommission |

The hard deadline is `britter.dev`'s 2026-12-21 expiry — everything after
Phase 2 has no deadline pressure and can slip without consequence.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Transfer rejected close to expiry | Start transfers ≥ 5 weeks before `britter.dev`'s expiry; transfers renew the domain on completion |
| Botched DKIM/SPF copy breaks mail | Byte-exact record copy in Phase 1 + parity check before any delegation change; Cloudflare zone untouched as rollback |
| ACME renewal fails mid-cycle on a backend | Old certs remain valid until natural expiry (~60+ days); restore-from-backup procedure in Phase 4 |
| Edge cert re-issuance outage (directions) | Force renewals deliberately, one vhost pattern at a time, with the `.bak`-restore fallback — never delete certs ahead of a verified renewal |
| INWX automation account lockout (2FA/credentials) | Dedicated sub-account, shared secret in sops, test a manual lego run from a shell before relying on it fleet-wide |
| Registrar-side lockout from INWX | Enable 2FA on the main account; registry lock / transfer lock on all three domains once settled |
| Renewal cost increase | Accepted consciously (see TLD table); INWX price list checked at execution time |
