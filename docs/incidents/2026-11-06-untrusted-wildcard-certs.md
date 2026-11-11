# Incident: untrusted certificates fleet-wide after switching to wildcard certs — 2026-11-06

After merging #349 (`https-proxy: request a single wildcard cert`), every
HTTPS name under `ritter.family` — LAN and tailnet — served a certificate
signed by an internal CA (`minica root ca *`) instead of the expected
Let's Encrypt certificate. Browsers flagged every homelab site as
untrusted; `beszel-agent` on directions logged
`tls: failed to verify certificate: x509: certificate signed by unknown
authority`.

## Timeline

| Time (CET) | Event |
|---|---|
| 09:43 | INWX DNS-01 issuance visibly working: `music.srv-prod-5.ritter.family` forced-renewed through INWX (per-vhost cert, #348) |
| 19:41 | #349 deployed fleet-wide (comin): one wildcard cert per host (`*.<host>.ritter.family`), plus `*.ritter.family` on directions |
| 19:41–19:48 | Every wildcard order fails at lego's DNS-01 propagation check; NixOS ACME falls back to self-signed `minica` certificates so dependent services still start |
| ~20:23 | Workaround deployed: `security.acme.defaults.dnsPropagationCheck = false` (#350, later reverted together with #349) |
| 20:39–20:42 | Retry attempts now fail *later* in the flow: lego passes the check, but Let's Encrypt rejects validation with `403 :: unauthorized :: No TXT record found at _acme-challenge.*` |
| later | The structural fix (challenge-node CNAME delegation in `tofu/dns/`, PR #352) could not roll out: the tofu CI's state backend is the fleet's own object store (`garage.srv-prod-3.ritter.family`), which was still serving the minica fallback → `x509: certificate signed by unknown authority` → CI blocked its own fix |
| later | **Reverted #349** (per-vhost certificates back); per-vhost Let's Encrypt certificates were still on disk and valid, so trusted certificates returned immediately (`home.ritter.family` verified) and the garage endpoint became LE-signed again |

## Root cause

Two stacked issues, both introduced by the **cert-shape change in #349** —
not by the Cloudflare → INWX migration (the same zone layout with
Cloudflare would have behaved identically; the per-vhost renewal at
09:43 through INWX proves the provider path itself is fine).

> **Addendum 2026-11-10:** both claims in that paragraph turned out to be
> wrong — the migration *was* a root cause (the zone was never actually
> delegated to INWX), and per-vhost challenge names *are* captured by the
> wildcard records. Renewals kept failing until 2026-11-10; see the
> [addendum](#addendum--2026-11-10-renewals-still-failing-the-delegation-was-never-flipped)
> at the bottom, which corrects this section.

### 1. Local: the UniFi gateway shadows the challenge names (first failure layer)

lego verifies DNS-01 propagation by querying the *system* resolver,
which on every host is the home network's gateway (`192.168.30.1`, see
`docs/split-dns.md`). The gateway answers `ritter.family` names from its
local zone, which contains wildcard records defined at exactly the depth
the new challenge names occupy:

```
challenge:  _acme-challenge.srv-prod-2.ritter.family   ← one extra label
gateway:    *.srv-prod-2.ritter.family (A record)       ← matches!
```

With per-vhost certs (#348 and earlier), challenge names were two labels
deep (`_acme-challenge.music.srv-prod-5.ritter.family`) and never
matched a local wildcard, so the gateway forwarded to the public zone
and the check passed. With #349's wildcard names, the gateway serves its
own (TXT-less) answer and lego's check always times out. Disabling the
propagation check (`dnsPropagationCheck = false`) is correct here:
Let's Encrypt validates the TXT record through INWX's authoritative
nameservers itself.

### 2. Public: the zone's wildcard CNAME records capture the challenge nodes (deeper layer; fix parked in PR #352)

Disabling the local check exposed the second layer. The public zone
(INWX, and identically Cloudflare before) contains per-host wildcard
CNAME records used for tailnet-direct routing
(`*.srv-prod-N.ritter.family` CNAME → the host). DNS wildcards match
any *single* extra label — so these records also match the new
challenge names:

```
dig @ns.inwx.de _acme-challenge.directions.ritter.family CNAME
  → directions.ritter.family.   (synthesized by *.directions.ritter.family)
```

lego's solver follows the CNAME when solving (logged as
`dns01: Found CNAME entry … cname=directions.ritter.family.`) and
writes the challenge TXT **at the CNAME target** (`directions.ritter.family`
itself — the zone data confirms the TXT sits there, next to the apex A
record). Let's Encrypt then validates `_acme-challenge.<host>` by chasing
the same chain, and — depending on resolver cache state, which poisoned
itself with NODATA during the earlier failed attempts (inwx SOA minimum
TTL is 3600 s) — finds no TXT and rejects with 403. The window between
lego's present/cleanup dance and LE's validation makes this flakily
racy rather than simply wrong; the result is repeated 403s and the
trace loop continues.

## Resolution

**Reverted #349.** Per-vhost cert configuration is back on the fleet,
and — crucial — the *on-disk* per-vhost certificates were stored from
earlier renewals and valid into January 2027, so trusted certificates
returned the moment the revert deployed, with no issuance necessary.
The revert also unblocked the fleet's own tooling: the tofu CI/apply
reaches its state backend through the S3 API of garage
(`garage.srv-prod-3.ritter.family`), which had been serving the minica
fallback for its own vhost — the catch-22 that made PR #352
(placeholder for the structural fix) impossible to merge or apply while
the fleet served untrusted certificates.

The wildcard-cert design is **parked, not discarded**: branch
`acme-dns01-fixes` (PR #352) carries the structural fix — explicit
`_acme-challenge.*` CNAME delegations in `tofu/dns/` that jail the
challenge TXT into the `acme.<host>.challenge` subtree (a depth no
wildcard record in either zone can capture), where lego/LE behave
deterministically; verified live during this incident that lego follows
CNAMEs and writes at the target. The follow-ups below describe how to
re-land it safely.

## Follow-ups

Re-landing the wildcard-cert design, in exactly this order (each step
removes the obstacle that blocked the previous attempt):

> **Resolution 2026-11-10:** the sequence was executed, but the
> challenge-delegation records turned out to be unnecessary. PR #352
> was rebased, merged (acf3bc1) and applied — and then judged a red
> herring and reverted the same day (#360), because the failures it
> was designed to fix were caused by the never-applied delegation
> flip (see the addendum), not by the wildcard capture itself. The
> wildcard design was re-landed **without** the records and works:
> all 9 wildcard certs were Let's Encrypt-signed by the evening of
> 2026-11-10. The records remain parked on `acme-dns01-fixes` as a
> determinism fix for the NODATA race (see standing notes); they can
> return with a single revert if issuance ever gets flaky.

- [x] Rebase `acme-dns01-fixes` (PR #352) on `main` (which now contains
      the #349 revert).
- [x] Confirm the tofu state backend is reachable again — post-revert,
      `garage.srv-prod-3.ritter.family` serves its per-vhost LE
      certificate, so `tofu init` (CI, plan, apply) works.
      -> Confirmed: both tofu-dns CI applies (13:46 and 14:45 UTC) succeeded.
- [x] ~~Merge PR #352~~ -> Merged (acf3bc1), challenge CNAMEs verified
      live in both zones — then **reverted** (#360): with the delegation
      actually flipped, per-vhost and wildcard orders validate fine
      through the wildcard-captured chain, and the records' only benefit
      (immunity to the NODATA race) doesn't outweigh the extra zone
      machinery. The re-landed module change must **also re-apply
      `dnsPropagationCheck = false`** — that change lived in #350 and
      was reverted together with #349 (it is harmless under per-vhost
      certs and mandatory under wildcard certs).
      -> Done in #360.
- [x] ~~Only once the delegation records exist in the zone: **revert the
      reverts**~~ -> Done in #360, deliberately *without* the delegation
      records. Every wildcard order meets the wildcard-synthesized
      CNAME, follows it to the host apex, and validates there — lego and
      Let's Encrypt chase the same chain in the same (now genuinely
      authoritative) zone.
- [x] Verify the fleet per cert: `openssl s_client -connect <vhost>:443
      … | openssl x509 -noout -subject -issuer -startdate` must show
      subject `*.<host>.ritter.family` (or `*.ritter.family` on
      directions), issuer **Let's Encrypt**, `notBefore` ≥ the
      re-landing deploy. Only then is this incident fully closed; until
      then untrusted names are the fallback state for any failed order.
      -> Done 2026-11-10: directions, srv-prod-2 … srv-prod-6 all green
      externally. Caveat: a failed order still falls back to minica
      (untrusted names) until its next successful retry — the daily
      renewal timer plus the ~30-day renewal margin make that
      self-healing.

Standing notes from this incident (independent of the revert):

- lego's present/cleanup-only failure path can leave the challenge TXT
  stranded at the CNAME target, and NODATA negative caching (inwx SOA
  minimum TTL 3600 s) can mask a successfully placed TXT for up to an
  hour for any resolver that queried before it landed. Useful for
  future DNS-01 debugging under split DNS. This cuts both ways:
  repeated failed validations poison resolvers with NODATA, and every
  retry that lands inside the previous attempt's one-hour window fails
  again even with the TXT correctly placed (observed on srv-prod-5,
  2026-11-10: three failures ~1 h apart, then green on the first retry
  after the window passed). Self-heals via the daily renewal timer
  well within the ~30-day renewal margin.
- Where lego places the TXT depends on whether the challenge node
  exists: with no record at `_acme-challenge.<X>`, the zone's wildcard
  synthesizes a CNAME and the TXT lands at the wildcard's target (the
  host apex); once a stranded TXT makes the node exist, wildcard
  synthesis no longer applies (NODATA on the CNAME query) and lego
  writes the TXT directly at the challenge node. Both paths validate.
  This explains the two distinct piles of stranded TXTs found in the
  INWX zone on 2026-11-10 (30 records across host apexes and
  `_acme-challenge.<vhost>` nodes) — all safe to delete, none
  tofu-managed.
- NixOS has **two** units per `security.acme` cert, and only one of
  them talks to Let's Encrypt: `acme-<cert>.service`
  ("Ensure certificate …") just regenerates the minica fallback and
  exits 0 — a green journal there means nothing; the real order is
  `acme-order-renew-<cert>.service` ("Order (and renew) ACME
  certificate"), which reloads nginx itself on success. Forcing
  re-issuance means stopping the order unit and moving
  `/var/lib/acme/<cert>/` aside (lego's own state — accounts and the
  issued cert — lives in `/var/lib/acme/.lego/<cert>/` and survives
  the move).
- The identical `minica root ca` fallbacks on every host (and the
  beszel-agent x509 warnings) are symptoms only; they self-heal once
  orders succeed.
- `srv-offsite-1.ritter.family` resolves to directions' LAN IP
  (`192.168.30.6`) in the local zone; SSH'ing there lands on directions,
  not srv-offsite-1. Either the local record (tofu `unifi_dns_record`)
  or the intent needs a look — separate from this incident but noticed
  while debugging it.

## Addendum — 2026-11-10: renewals still failing; the delegation was never flipped

Four days after the #349 revert, per-vhost renewals were still failing
deterministically (`books.srv-prod-2.ritter.family`, lego
`dns01: time limit exceeded` at the gateway). Root cause this time: the
**registrar transfer to INWX (completed 2026-11-05 19:24) preserved the
losing registrar's nameserver delegation** — the registry still pointed
`ritter.family` at `isabel`/`salvador.ns.cloudflare.com`. Phase 4 of the
[DNS migration](../plans/archive/2026-11-11-cloudflare-to-inwx-dns-migration.md) had been
marked done from the INWX panel's *zone editor*, which shows the INWX
nameservers of the hosted zone — but that zone was inert, exactly as the
tofu comment warns ("While the domains still delegate to Cloudflare these
zones are inert").

What that produced, on top of the original two failure layers:

- lego writes challenge TXTs through the INWX API into the **inert**
  zone; Let's Encrypt validates via the delegated (Cloudflare)
  nameservers and can never see them → orders fail deterministically,
  not flakily.
- The gateway (`192.168.30.1`) forwards TXT queries into the delegated
  zone, which still serves a **stranded challenge TXT** (`0IIcv-…`) at
  the `srv-prod-2.ritter.family` apex from the pre-#348 era — the wrong
  value, so lego's propagation check times out with the confusing
  signature "did not return the expected TXT record" naming an unrelated
  value.
- The Cloudflare zone still existing was *not* the problem (it is the
  Phase 6 rollback path); the problem was that it was still the
  **delegated** authority.

**Correction to the root-cause analysis above:** the claim that per-vhost
challenge names are two labels deep and never match a wildcard is wrong.
Verified live on 2026-11-10 with a random probe
(`_acme-challenge.zzzzrandom9zz.srv-prod-2.ritter.family`) against both
providers: **Cloudflare and INWX both synthesize the wildcard CNAME for
multi-label names** under `*.<host>.ritter.family`. Every per-vhost
order whose vhost adds a label (e.g. `books.srv-prod-2`,
`music.srv-prod-5`) is captured and redirected to the apex today — not
just wildcard certs. (This also undermines the timeline's 09:43 "INWX
works" proof: an INWX-written TXT could not have validated under
Cloudflare delegation, so treat that event as unexplained.)

### Fix: flip the delegation in the INWX web UI

The delegation is not editable in the zone editor — the zone's `MASTER`
record and its NS records are zone data with no effect on the registry
delegation. The working path in the INWX web UI:

> **Domain → Domainliste → in the list of domains, click the little gear
> at the right-hand side → Externe Nameserver → flip the switch from
> "Externe Nameserver" to "INWX Nameserver".**

(Editing the zone record instead prompts "Master IP-Adresse erforderlich"
— that field only applies to SLAVE/secondary zones; leave the zone
alone.)

Verify at the registry, not in the panel (delegation NS TTL 3600, no DS
record — `delegationSigned: false` — so no DNSSEC risk):

```sh
dig ritter.family NS @v0n0.nic.family +norecurse
# expect: ns.inwx.de / ns2.inwx.de / ns3.inwx.eu
```

-> Confirmed 2026-11-10: the registry flipped within the hour of the
panel change. Caveat observed live: some big resolvers (1.1.1.1,
9.9.9.9) kept answering Cloudflare NS for a while — they had cached the
**apex NS RRset from inside the Cloudflare zone, which is served with
TTL 86400** and outranks the registry referral per RFC 2181. That
stale-cache window is self-limiting (≤ 24 h) and harmless while both
zones are in parity, but ACME validation routed through such resolvers
can still see the old zone during it — retry a failed renewal a few
hours later before debugging anything.

Then trigger one renewal (`systemctl start
acme-order-renew-books.srv-prod-2.ritter.family.service`) — a green
order is the functional proof of the flip.

### Follow-ups added 2026-11-10

- [x] Confirm `dig ritter.family NS @v0n0.nic.family` shows the INWX NS
      and a per-host renewal succeeds.
      -> Registry delegation confirmed flipped 2026-11-10 (registry
      showed INWX NS within the hour; 1.1.1.1 / 9.9.9.9 lagged on the
      cached apex NS RRset, TTL 86400, see above). Renewals green the
      same day: `books.srv-prod-2` / `garage.srv-prod-3` in the morning
      (first green orders through the correctly delegated zone), the
      rest with the wildcard re-land in the afternoon — all 9 wildcard
      certs Let's Encrypt-signed by evening. Big resolvers confirmed
      INWX-routed (apex TXT shows only the brevo-code record, no
      Cloudflare-zone strays).
- [x] Remove stranded challenge TXT records at the apexes: seven at
      `srv-prod-2.ritter.family` in the INWX zone
      (`dig @ns.inwx.de srv-prod-2.ritter.family TXT`), the
      `0IIcv-…` record at the apex in the Cloudflare zone. They are not
      tofu-managed — remove via the panel/API.
      -> 2026-11-10: 30 stranded TXTs removed from the INWX zone (they
      sat at host apexes *and* at `_acme-challenge.<vhost>` nodes — see
      the standing notes for why two piles). The `0IIcv-…` record in the
      Cloudflare zone is still there — remove it together with the zone
      itself in Phase 6 of the migration plan.
- [x] Flip `britter.dev` and `benediktritter.de` to the INWX nameservers
      too (same UI path; verify the Netlify checks from the migration
      plan's Phase 4 afterwards).
      -> Done and registry-verified 2026-11-10 (`.dev`:
      ns-tld1.charlestonroadregistry.com, `.de`: f.nic.de both show the
      INWX NS). Netlify checks green (britter.dev 200 / Netlify,
      benediktritter.de 301 → https://britter.dev/).
- [ ] Consider managing the delegation in tofu via the `inwx_domain`
      resource (`nameservers` argument, import the existing domains) so
      panel state can't silently drift from the registry again.
