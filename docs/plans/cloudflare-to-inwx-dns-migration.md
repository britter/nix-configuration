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

- RDAP shows `britter.dev` expiring 2026-12-21 (≈ 7 weeks out — this drives the
  schedule), but `ritter.family` expires 2027-06-28, roughly eight months away.
  Worth double-checking the Cloudflare billing dashboard in case RDAP reflects a
  recently renewed term, but the plan proceeds on the RDAP data: `britter.dev` is
  pressing, `ritter.family` is not.
- Both Cloudflare-registered domains show `last changed` more than 60 days ago
  (`ritter.family`: 2026-08-12, `britter.dev`: 2025-11-26), so the ICANN 60-day
  transfer lock after a registrant change does not apply.
- `britter.dev` has zone signing enabled without a published DS record — an
  incomplete DNSSEC state. Nothing validates against it today. This plan does
  **not** introduce DNSSEC; see Phase 0 for the recommendation to switch signing
  off first.
- DNS records are managed in `tofu/dns/cloudflare/` (OpenTofu): `main.tf`,
  `directions.tf` (the `*.ritter.family` and `*.srv-prod-N.ritter.family`
  wildcards the proxy stack depends on), and `email.tf` (mail records —
  SPF/DKIM/DMARC must be carried over exactly; see Phase 2 verification).

### Web hosting on `britter.dev` / `benediktritter.de` (verified via live DNS/HTTP, 2026-11-03)

Both domains currently serve the same static website: the Netlify site
**`britter-dev`**, built from `https://github.com/britter/website`.

| Record | Value | Serves |
|---|---|---|
| `britter.dev` CNAME @* | `apex-loadbalancer.netlify.com` (flattened to A `75.2.60.5`, `99.83.231.61` by Cloudflare) | HTTP 200, `server: Netlify` |
| `www.britter.dev` CNAME | `britter-dev.netlify.app` | HTTP 200, same site |
| `benediktritter.de` CNAME @* | `apex-loadbalancer.netlify.com` (flattened to A `75.2.60.5`, `99.83.231.61` by Cloudflare) | HTTP **301 → `https://britter.dev/`** |
| `www.benediktritter.de` CNAME | `britter-dev.netlify.app` | HTTP 200, same site (identical etag to `britter.dev`) |

\* Live `dig` answers with A records — Cloudflare flattens apex CNAMEs. On
the wire/in the zone they are CNAMEs.

Notes:

- The `benediktritter.de` → `britter.dev` apex redirect is a **Netlify-side
  redirect rule** (and the domains are aliases of the same Netlify site), not
  a DNS-level thing. It survives the DNS migration as long as the records
  above are copied 1:1 — nothing to re-configure, but verify it after the NS
  flip (Phase 4).
- **The apex records cannot be ported as plain CNAMEs.** Cloudflare flattens
  apex CNAMEs; standard DNS forbids CNAME at the apex and INWX will reject
  them. INWX offers an `ALIAS` record type for exactly this (apex →
  `apex-loadbalancer.netlify.com`), with one caveat: ALIAS limits/breaks
  DNSSEC on the zone. That is fine here — the plan deliberately skips DNSSEC
  (see Phase 0) — but it is another reason *not* to turn DNSSEC on later
  without revisiting these two apex records.
- Neither zone carries mail records (no MX, no SPF/DKIM/DMARC TXT). They are
  web-only zones, so Phase 2's byte-exact mail worry only concerns
  `ritter.family`.
- **These records live in the private repo `github.com/britter/domains`**
  (Terraform, Cloudflare provider ~4, files `britter-dev.tf` /
  `benediktritter-de.tf`) — not in `tofu/dns/cloudflare/` here, which manages
  only `ritter.family`. The consolidation into `tofu/dns/inwx/` in this repo
  has not happened yet; Phase 2 is the natural moment to do it: port the
  records from `britter/domains` into `tofu/dns/inwx/` and retire the old
  repo once the INWX zones are authoritative. If the consolidation slips,
  port from the repo's HCL directly rather than re-enumerating the dashboard.
- ⚠️ The same `britter/domains` repo also manages a **fourth Cloudflare
  zone, `autoweird.fm`** (`autoweird-fm.tf`), which is out of scope for this
  migration (not registered/dns-hosted by this plan). Keep it in mind in
  Phase 6 — do not treat "delete the Cloudflare zones" as "empty the whole
  Cloudflare account".

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

- [x] Create an INWX account under **inwx.de** (German entity, EUR billing,
      matches where you live). Note that inwx.de / inwx.com / inwx.ch /
      inwx.at are separate entities with different currencies and VAT.
- [x] Create a dedicated **sub-account** for automation with access to the
      three domains and their nameserver entries — do not use the main
      login for ACME. Enable 2FA on the main account; note the TOTP
      shared secret of the *automation* account, since lego needs it
      (`INWX_SHARED_SECRET`) if 2FA is active there too.
- [x] Stash the INWX automation-account credentials (`acme/inwx-username`,
      `acme/inwx-password`, and `acme/inwx-shared-secret` if the account
      uses 2FA) in your password manager for now — their sops home is the
      module-local shared `secrets.yaml` created in Phase 1.
- [x] Check both Cloudflare-registered domains in the dashboard:
      registrar transfer lock status, auto-renew status, and confirm the
      expiry dates seen via RDAP.
- [x] Check `benediktritter.de` in the Hosting Europe panel: expiry date,
      DNSSEC status, and whether an authinfo code can be generated there.
      expires on 19.02.2027, no DNSSEC.
- [x] **DNSSEC:** switch off zone signing for `britter.dev` in Cloudflare
      (it is incomplete anyway — signed zone, no DS in the parent), and
      confirm `ritter.family` has no DNSSEC. Revisit DNSSEC as a separate
      project after the migration; INWX and all three TLDs support it.
      -> DNSSEC not turned on in Cloudflare according to the dashboard.
- [x] Add the INWX provider to `tofu` (`inwx/inwx` from the OpenTofu
      registry) with the automation account's credentials via
      `secrets.json`/environment, mirroring how the Cloudflare provider is
      configured today.

## Phase 1 — Collapse per-host ACME secrets into one shared sops file

This step is **independent of the migration** and deliberately scheduled
before any domain moves: it proves the shared-secrets shape while
everything still runs on Cloudflare, and turns the Phase 5 provider flip
into a value-only change.

Today every host carries its own Cloudflare token in its own
`secrets.yaml`, generated by `tofu/dns/cloudflare/main.tf`
(`cloudflare_api_token` with `for_each = var.host_ips`) and pasted in
manually — a bootstrap dance (boot host → join tailscale → tofu sees it →
generate token → paste into sops). All those tokens are scoped "DNS Write"
to the `ritter.family` zone and Cloudflare has no record-level token
scoping, so they are capability-equivalent to a single shared credential —
and INWX has no scoped tokens at all (lego uses username/password of the
automation account), so the shared model is where this ends up regardless.

- [ ] Restructure `modules/nixos/https-proxy.nix` into a directory module
      (precedent: `modules/nixos/nextcloud/`):
      `modules/nixos/https-proxy/{default.nix,secrets.yaml}`.
- [ ] Add a `.sops.yaml` creation rule for
      `modules/nixos/https-proxy/secrets\.yaml$` listing `*framework-13`
      plus the age anchors of **every host that imports the module**.
      This recipient list is the credential's access list — keep it in
      sync when hosts are added or retired. After every list change, run
      `sops updatekeys modules/nixos/https-proxy/secrets.yaml` (a missing
      key fails loudly at activation, so it cannot be forgotten silently —
      but only at the next deploy).
- [ ] Create **one** Cloudflare token manually: DNS Write, scoped to
      `ritter.family` only (least privilege, same as the per-host tokens
      were). Put its value in the shared `secrets.yaml` under the existing
      key name `acme/cloudflare-dns-api-token`.
- [ ] In `default.nix`, point the secret at the module-local file:
      ```nix
      sops.secrets."acme/cloudflare-dns-api-token" = {
        sopsFile = ./secrets.yaml;
      };
      ```
      The module keeps declaring the secret as before — hosts pick it up
      automatically; their per-host `secrets.yaml` files no longer contain
      any ACME entry.
- [ ] Remove the token-generation machinery from tofu: the
      `cloudflare_api_token` resource, the `acme_tokens` output, and the
      README's clipboard instructions (`tofu/dns/cloudflare/main.tf`,
      `README.md`). The DNS records (`main.tf`, `directions.tf`,
      `email.tf`) stay.
- [ ] Redeploy all hosts and confirm certs still renew (no action needed
      until natural renewal — the token value is the same credential class
      as before). From this point on, a credential or provider change is
      an edit to one shared file plus a module change, deployed per host.

Note: keep this shared file for fleet-wide ACME credentials only. Its
recipient list is coarse (every proxy host), so service-level secrets do
not belong in it.

## Phase 2 — Replicate all three zones in INWX (non-authoritative)

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
      - the **Netlify web records** for `britter.dev` and
        `benediktritter.de` (see the table in "Current state"), ported
        from the `britter/domains` repo:
        - `www` CNAME → `britter-dev.netlify.app` (both zones, plain CNAME works at INWX),
        - apex records: currently CNAME → `apex-loadbalancer.netlify.com`
          with Cloudflare flattening. At INWX these must become **ALIAS
          records** with the same target (INWX rejects apex CNAMEs; its
          ALIAS type synthesises A/AAAA answers like Cloudflare flattening
          does — but limits DNSSEC on the zone).
      While at it, this is the consolidation point: move the
      `britter/domains` records into `tofu/dns/inwx/` in this repo so all
      zones end up managed in one place, and retire `britter/domains` after
      the cutover. Note `britter/domains` also manages `autoweird.fm`,
      which stays out of scope here.
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

## Phase 3 — Registrar transfers (the time-critical phase)

Start this phase immediately after Phase 2 — `britter.dev` expires
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

## Phase 4 — Nameserver delegation flip (the cutover moment)

One domain at a time, lowest-stakes first. Suggested order:
`benediktritter.de` → `britter.dev` → `ritter.family` (the homelab's
primary domain, most traffic, goes last once the procedure is proven).

- [ ] Set the nameservers at the (new) registrar — INWX panel for all
      three now, or Hosting Europe's panel for the .de if its transfer is
      deliberately deferred:
      `ns.inwx.de`, `ns2.inwx.de`, `ns3.inx.wtf`.
- [ ] Propagation of a delegation is TTL-bound (typically hours, up to
      `NS`/`SOA` TTL). Resolvers will serve a mix of old and new NS
      answers during the window — both zones are identical (Phase 2), so
      this is transparent.
- [ ] Verify from the outside:
      ```sh
      dig +trace ritter.family NS
      dig @1.1.1.1 books.ritter.family   # resolves, via new NS
      dig @8.8.8.8 nextcloud.ritter.family
      ```
- [ ] Watch gatus monitors and mail logs for the propagation window.
- [ ] After flipping `britter.dev` or `benediktritter.de`, verify the
      Netlify site still serves and the apex redirect still works:
      ```sh
      curl -sI https://britter.dev | grep -i '^HTTP\|^server'
      curl -sI https://benediktritter.de | grep -i '^HTTP\|location'
      # expect: 200 / Netlify on the first, 301 → https://britter.dev/ on the second
      ```

Rollback for this phase: flip the delegation back at the registrar. The
Cloudflare zones remain intact and in sync until Phase 6, so rollback is
always available within minutes.

## Phase 5 — Flip ACME DNS-01 to INWX (per host, with the comin model)

Each host evaluates and builds its own configuration, so the flip is per
host and independently verifiable. lego's INWX provider is built into
`security.acme`'s lego package — no new dependencies.

The shared `modules/nixos/https-proxy/secrets.yaml` and the module-local
sops wiring already exist since Phase 1, so this phase only changes the
provider and the credential values.

- [ ] In `modules/nixos/https-proxy/default.nix`, change the
      `security.acme.defaults` block:
      ```nix
      dnsProvider = "inwx";
      credentialFiles = {
        "INWX_USERNAME_FILE" = config.sops.secrets."acme/inwx-username".path;
        "INWX_PASSWORD_FILE" = config.sops.secrets."acme/inwx-password".path;
        # only if the automation account has 2FA:
        # "INWX_SHARED_SECRET_FILE" = config.sops.secrets."acme/inwx-shared-secret".path;
      };
      ```
- [ ] Add the INWX automation-account credentials to the **shared**
      `modules/nixos/https-proxy/secrets.yaml` (`acme/inwx-username`,
      `acme/inwx-password`, and optionally `acme/inwx-shared-secret`).
      One `sops edit`, no per-host work. Keep the
      `acme/cloudflare-dns-api-token` entry in the same file until every
      cert has renewed once (rollback path).
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

## Phase 6 — Decommission Cloudflare

Only once **every** certificate on every host has renewed at least once
through INWX (check `/var/lib/acme/*/account*` or cert issuer), and the
gatus monitors have been green across a full cert cycle:

- [ ] Delete the three migrated zones (`ritter.family`, `britter.dev`,
      `benediktritter.de`) from the Cloudflare account. **Careful:** the
      account also hosts `autoweird.fm` (managed by the `britter/domains`
      repo) — leave that zone and its API-token scope untouched, or migrate
      it in a follow-up.
- [ ] Remove the `acme/cloudflare-dns-api-token` entry from the shared
      `modules/nixos/https-proxy/secrets.yaml` and remove the
      `credentialFiles` line from
      `modules/nixos/https-proxy/default.nix`.
- [ ] Remove `tofu/dns/cloudflare/` (after confirming nothing else uses
      that provider/state) and the Cloudflare provider block.
- [ ] Confirm INWX auto-renew is enabled for all three domains, payment
      method on file, and expiry dates transferred/imported correctly
      (INWX imports the remaining registration term on transfer).

## Timeline

| When | What |
|---|---|
| Week of 2026-11-09 | Phase 0, Phase 1, Phase 2: account + credentials, secrets consolidation (independent of the migration), tofu port, zones replicated and verified |
| Week of 2026-11-16 | Phase 3: initiate all three transfers (britter.dev deadline buffer: transfer must complete before 2026-12-21; ≤ 5 days once initiated) |
| Late Nov 2026 | Phase 4: NS flips, one domain at a time |
| Early Dec 2026 | Phase 5: ACME flip across hosts, srv-prod-5 pilot → directions → rest |
| ≥ one renewal cycle later | Phase 6: Cloudflare decommission |

The hard deadline is `britter.dev`'s 2026-12-21 expiry — everything after
Phase 3 has no deadline pressure and can slip without consequence.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Transfer rejected close to expiry | Start transfers ≥ 5 weeks before `britter.dev`'s expiry; transfers renew the domain on completion |
| Botched DKIM/SPF copy breaks mail | Byte-exact record copy in Phase 2 + parity check before any delegation change; Cloudflare zone untouched as rollback |
| Missed Netlify record takes britter.dev / benediktritter.de offline | Records are IaC-managed in `britter/domains` — port the HCL 1:1 in Phase 2 and run the `curl` checks after the NS flip (Phase 4) |
| Apex CNAME rejected at INWX (no flattening) | Use INWX `ALIAS` records → `apex-loadbalancer.netlify.com`; verify `dig <domain> A` returns Netlify LB IPs before the NS flip |
| ACME renewal fails mid-cycle on a backend | Old certs remain valid until natural expiry (~60+ days); restore-from-backup procedure in Phase 5 |
| Edge cert re-issuance outage (directions) | Force renewals deliberately, one vhost pattern at a time, with the `.bak`-restore fallback — never delete certs ahead of a verified renewal |
| INWX automation account lockout (2FA/credentials) | Dedicated sub-account, shared secret in sops, test a manual lego run from a shell before relying on it fleet-wide |
| Registrar-side lockout from INWX | Enable 2FA on the main account; registry lock / transfer lock on all three domains once settled |
| Renewal cost increase | Accepted consciously (see TLD table); INWX price list checked at execution time |
