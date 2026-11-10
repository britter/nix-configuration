# Home Assistant: Keycloak SSO (next native client)

**Status:** complete (2026-11-10), archived per AGENTS.md — the
`OpenTofu Keycloak` pipeline applied the client (probe verified), the
`OpenTofu Network` pipeline applied the firewall route, the device
click-ops landed (HACS + `hass-oidc-auth` UI config), and the first SSO
login landed in the existing admin account 2026-11-10. Local password
login stays enabled (break-glass + companion-app provider). Follow-ups
live in the Status section: second household realm user, then linking
off. Part of [`../keycloak-sso-rollout.md`](../keycloak-sso-rollout.md)
(step 3, "remaining native apps"). Client conventions follow the Forgejo,
PVE, Beszel and Stirling PDF onboardings.

## Background

Home Assistant runs on the Home Assistant Green appliance (HAOS,
`192.168.20.234:8123`, Smart Home VLAN) — **not** NixOS- or tofu-managed.
Click-ops plus guardrails is the accepted pattern for this device; managing
its `configuration.yaml` in git was evaluated and rejected
([`2026-11-03-home-assistant-config-git.md`](archive/2026-11-03-home-assistant-config-git.md)).
Its configuration lives in UI storage (`.storage/`) and device-local files;
`secrets.yaml` on the device is untracked by anything.

Dependencies and facts to know about:

- **Correction to the rollout table: HA core has no built-in OIDC.** The
  built-in auth providers are still `homeassistant`, `trusted_networks` and
  `command_line` (HA 2026.11); no OIDC provider exists in core. The
  established relying-party integration is the HACS custom component
  [`christiaangoossens/hass-oidc-auth`](https://github.com/christiaangoossens/hass-oidc-auth)
  ("OpenID Connect/SSO Authentication", stable since v1.0.0, current
  v1.2.1): RFC 7636 (PKCE) and RFC 9700 conformant, ships an official
  Keycloak provider guide, and has a UI config flow. This is still
  "native" in the rollout plan's sense — the app itself consumes OIDC, no
  auth proxy sits in front — but the SSO code is a HACS component, not
  core.
- **The trusted-proxy half is already done.** The rollout table's comment
  ("Needs a trusted-proxy setup so local logins stay possible") refers to
  the setup fixed in
  [`docs/incidents/2026-11-02-home-assistant-unreachable.md`](../incidents/2026-11-02-home-assistant-unreachable.md):
  since HA 2026.8 the proxy-trust config lives in UI storage, and
  `directions`' IP (`192.168.30.6`) is already a trusted proxy. The nginx
  side forwards `X-Forwarded-Proto/Host` (`recommendedProxySettings`), so
  the integration builds its redirect URI as `https://…`. Local logins
  stay possible because the built-in `homeassistant` auth provider remains
  registered — SSO adds a login method, it does not remove one.
- **One pre-existing account:** the local admin user on the device. The
  realm user is `bene` (`beneritter@gmail.com`, verified). The goal is the
  Forgejo/Beszel outcome: the first SSO login lands in the existing admin
  account — dashboards, devices, automations intact.
- **HA is also an OAuth2 *provider*** (companion app, Music Assistant, …).
  The integration is RP-only (client side) and does not touch that —
  upstream fixed the interaction with external OAuth2 apps in v1.1.1.

## Chosen approach

The Keycloak side follows the one-file-per-client convention:
`tofu/keycloak/client-homeassistant.tf`, applied by the existing
`OpenTofu Keycloak` pipeline on merge. Two deliberate deviations from the
other clients:

1. **Public client, no secret.** Every other client is confidential with
   an operator-generated secret seeded into sops stores. Here that model
   collapses: the HAOS device has no sops store, so the secret would live
   only in device-local files (`/config/secrets.yaml` or UI `.storage`)
   with no git source of truth and nothing to verify the two copies
   against — the exact state the Forgejo plan rejected for
   `client_secret_regenerate_when_changed`, but permanent. The
   integration's own docs recommend a **public client** for home settings:
   "using properly configured redirect URLs + PKCE already provides enough
   security" (docs/configuration.md). hass-oidc-auth sends PKCE (S256) by
   default (`features.disable_rfc7636`, default false), so the client
   enforces `S256` and the redirect URI is pinned to the exact callback —
   that is the whole security model, and it needs no secret anywhere.
   The sops seeding step other plans start with does not exist here.
2. **No PKCE negotiation, unlike Stirling PDF.** Forgejo, Beszel and
   hass-oidc-auth all send the challenge, so `pkce_code_challenge_method =
   "S256"` is enforced (the Forgejo-plan probe shape applies verbatim).

The app side is configured **via the UI config flow**, not YAML:
Settings → Devices & Services → Add Integration → "OpenID Connect/SSO
Authentication" → discovery URL + client id, and the user-linking screen
that v1's UI flow provides. Roles/group mapping (YAML-only) is not needed
for a one-person realm, which also avoids the Keycloak groups-mapper
click-ops the upstream Keycloak guide describes. The YAML alternative
(`auth_oidc:` block in `configuration.yaml`, secret via `!secret`) was
rejected: it cannot express anything the UI flow doesn't here, and it adds
a device-local file edit (web editor, no review) where the guided flow
validates the discovery URL inline.

**User linking is migration scaffolding.** `automatic_user_linking` matches
the OIDC username claim (`preferred_username` → `bene`) against the local
user's username, case-exact, and links the SSO credential onto that
account. Upstream recommends it only temporarily (any realm user whose
username matches an HA account takes that account over; HA-side MFA is
bypassed on the match — the realm is admin-provisioned with registration
off, so today the userbase *is* the allow-list).

**Decision 2026-11-10: linking stays on beyond the first login,
deliberately.** The household has a second HA account (operator's wife)
that has no realm identity yet (`tofu/keycloak/users.tf` holds only
`bene`) — linking is what will land her first SSO login in her existing
HA account when she is provisioned. Until then the flag affects only
*first-time* realm identities (linked accounts authenticate by their IdP
`sub` and are unaffected), and provisioning realm users is admin-only.
End condition: disable automatic user linking once the second realm user
has linked once (see Status → follow-ups).

**Password login stays enabled.** The rollout plan asks for the pros/cons
of disabling it:

- **Pro (disable):** no second phishable credential; one password policy,
  one forgot-password flow (realm SMTP via Brevo).
- **Con (disable):** the smart home's availability would depend on
  srv-prod-1 being up — HA is the one service in this fleet where the
  auth IdP going down locks the *house*, not just a tab. Beszel and
  Stirling accepted that; their break-glass is a config-file edit.
- **Con (disable, HA-specific):** the companion apps' refresh tokens are
  tied to the `homeassistant` auth provider — removing that provider (or
  hiding the login it owns behind `default_redirect`) breaks app
  re-authentication (`InvalidProvider: Auth provider homeassistant not
  available`), and there is no declarative env line to flip back; the
  change lives in UI storage on an appliance with no sops and no git.
- **Decision: keep password login** (the local user remains
  break-glass, as `root@pam` is for PVE). The login screen shows a
  "Sign in with Keycloak" button beside the password form;
  `default_redirect: true` (skip the password form, reachable at
  `?skip_oidc_redirect=true`) is a possible follow-up after a soak
  period, not part of this rollout.

Staging:

| Stage | What | Where |
| --- | --- | --- |
| 0 | tofu client | PR 1 (`OpenTofu Keycloak` pipeline applies; file already in the tree) — ✅ applied 2026-11-10, probe verified |
| 1 | Firewall route Smart Home → directions :443 | PR 2 (`OpenTofu Network` pipeline applies; file already in the tree) — ✅ applied, discovery URL answers `200` from the device |
| 2 | Device click-ops: HACS + integration + UI config | Part B, operator (~10 min) — ✅ 2026-11-10 |
| 3 | First SSO login lands in the existing admin | Part C, operator — ✅ 2026-11-10 |
| 4 | Completion | docs/homelab.md, rollout table, archive — ✅ |

There is no comin event and no NixOS change in this rollout: the only live
events are the two pipeline applies (the `keycloak` and `network` tofu
roots) and the device click-ops (PVE's shape, not Forgejo's).

## Part A — tofu client (PR 1)

Full diff of the new file (this is `tofu/keycloak/client-homeassistant.tf`
as it lands in the PR — identical to the file created alongside this
plan):

```diff
@@ tofu/keycloak/client-homeassistant.tf @@
+# One OIDC client per service, one file per client.
+resource "keycloak_openid_client" "homeassistant" {
+  realm_id  = keycloak_realm.homelab.id
+  client_id = "homeassistant"
+  name      = "Home Assistant"
+  enabled   = true
+
+  # Deliberately PUBLIC, unlike the other clients: Home Assistant runs on
+  # the HAOS Green appliance, which has no sops store — a confidential
+  # secret would live only in device-local files (/config/secrets.yaml or
+  # UI .storage) with no git source of truth and nothing to verify it
+  # against. The integration's own docs recommend a public client with
+  # redirect-URI + PKCE for home settings; hass-oidc-auth sends PKCE
+  # (S256) by default, so the enforcement below is the security model.
+  # See docs/plans/homeassistant-keycloak-sso.md.
+  access_type                  = "PUBLIC"
+  standard_flow_enabled        = true
+  direct_access_grants_enabled = false
+  # hass-oidc-auth sends PKCE (S256) on the authorization-code flow
+  # (RFC 7636); only features.disable_rfc7636 would turn it off, left at
+  # its default false.
+  pkce_code_challenge_method = "S256"
+
+  # hass-oidc-auth builds the redirect URI from the request origin plus
+  # the fixed callback path /auth/oidc/callback. Logins opened at the raw
+  # LAN address (http://192.168.20.234:8123) would send a different origin
+  # and fail Keycloak's redirect check — the public FQDN is the one
+  # supported SSO entry point (same caveat as PVE and Beszel); direct LAN
+  # access uses the local password login, which stays enabled as
+  # break-glass.
+  valid_redirect_uris = [
+    "https://homeassistant.ritter.family/auth/oidc/callback",
+  ]
+}
```

Verify locally, then open the PR:

```bash
cd tofu/keycloak
tofu fmt -check     # ✅ exit 0 locally (2026-11-10)
tofu validate       # ✅ Success — configuration is valid (providers cached from prior init)
tofu plan           # ⏳ expected: + keycloak_openid_client.homeassistant, nothing else
```

(`tofu plan` needs the state-bucket credentials from `.envrc` — direnv. No
sops seeding step exists: there is no secret.)

`nix fmt` from the repo root, then open the PR. The pipeline's plan
comment must show `+ keycloak_openid_client.homeassistant` **only**. Merge;
the pipeline applies the client. Then probe from the public side — the
Forgejo-plan probe shape: request the authorize endpoint with the
registered redirect URI and *deliberately without* a `code_challenge`, and
read where the 302 points:

```bash
curl -sS -o /dev/null -D - \
  "https://account.ritter.family/realms/homelab/protocol/openid-connect/auth?client_id=homeassistant&response_type=code&state=probe&redirect_uri=https%3A%2F%2Fhomeassistant.ritter.family%2Fauth%2Foidc%2Fcallback" \
  | sed -n '1p; /^[Ll]ocation:/p'
# expected: 302 whose Location: is
#   https://homeassistant.ritter.family/auth/oidc/callback?state=probe&error=invalid_request&error_description=Missing…code_challenge…
#
# ✅ verified 2026-11-10 (Part A applied):
#   HTTP/2 302
#   location: https://homeassistant.ritter.family/auth/oidc/callback?error=invalid_request&error_description=Missing+parameter%3A+code_challenge_method&state=probe&iss=https%3A%2F%2Faccount.ritter.family%2Frealms%2Fhomelab
#
# negative controls (same moment):
#   unknown client_id (homeassistant-does-not-exist) → 400
#   registered client_id + unregistered redirect_uri → 400 (no open redirect)
```

That error is exactly what an *enforced* challenge should produce, and it
proves in one response that the client exists and the callback URI is
registered. Before the client exists the probe answers `400` (client not
found), so this also proves the apply.

Stage gate: the probe must answer the PKCE-error 302 before Part B starts,
otherwise the login page shows a dead SSO button.

Rollback (Part A): `git revert`; the next pipeline apply deletes the
client — state-based, no manual Keycloak action. Nothing else exists yet.

## Part B — device click-ops: install and configure (operator, ~10 min)

Ordered so the SSO button appears only after the Keycloak client is live
and the device can actually reach it. Local password login is unaffected
throughout — the built-in `homeassistant` auth provider is never removed.

1. **Confirm the network route** (the gate for this part). The device
   sits in the Smart Home VLAN; inter-VLAN traffic is default-deny
   (every existing flow has an explicit ALLOW policy in
   `tofu/network/firewall_policies.tf`), and before this rollout none
   covered Smart Home → Servers. `unifi_firewall_policy.homeassistant_to_directions`
   (PR 2, mirroring the `directions_to_pve` client-to-IP pattern) allows
   the device's OIDC calls: `account.ritter.family` resolves via the UDM
   wildcard record (`tofu/network/dns.tf`) to directions
   (`192.168.30.6`), which proxies to Keycloak on srv-prod-1 — same-VLAN,
   no further firewall hop. The discovery URL is fetched once at setup
   and the token endpoint is hit at **every SSO login**, so without the
   rule the config flow times out at "validate discovery URL" and no
   login can complete. After the `OpenTofu Network` pipeline applies
   PR 2, verify end-to-end from the device's terminal:

   ```bash
   curl -s -o /dev/null -w '%{http_code}\n' \
     "https://account.ritter.family/realms/homelab/.well-known/openid-configuration"
   # expected: '200'
   ```
2. Confirm the client is live: the `OpenTofu Keycloak` pipeline is green
   and the Part A probe answers the PKCE-error 302.
3. **HACS check.** Settings → Devices & Services shows "HACS" (or
   `/config/custom_components/hacs` exists via the File editor). If HACS
   is not installed yet, install it first per hacs.xyz (download +
   restart) — that restart is a brief outage, gatus tolerates it.
4. HACS → search **"OpenID Connect"** →
   `christiaangoossens/hass-oidc-auth` → Download → restart HA when
   prompted. (Brief outage; gatus 5m check tolerates.)
5. Settings → Devices & Services → Add Integration → **OpenID
   Connect/SSO Authentication** → provider **OpenID Connect (SSO)** (the
   generic one, not a preset):
   - Discovery URL:
     `https://account.ritter.family/realms/homelab/.well-known/openid-configuration`
   - Client ID: `homeassistant`
   - Client Secret: **leave empty** (public client)
   - The flow validates the discovery URL against the realm before
     continuing — a timeout here means the firewall rule hasn't landed;
     an IdP-side error means Part A's apply didn't land.
6. On the **user-linking screen**: enable **automatic user linking**
   (see the decision above: it stays on until every household realm
   user has linked once, then goes off). Leave group/role options
   untouched (no groups are in play).

All of this lives in UI storage on the device — it is click-ops by
policy; the recovery path is re-doing these steps, recorded in
`docs/homelab.md` (Part 1 of this plan adds that section).

## Part C — first SSO login (the goal) ✅ (2026-11-10)

1. **Pre-check:** the local HA user's username must match the Keycloak
   `bene` username exactly (case-sensitive — upstream discussion #276 is
   a case-mismatch support thread). Check under Settings → People → the
   admin user. If it differs, rename the local user or expect a fresh
   (unprivileged) HA user to be created instead.
2. Private browser window → `https://homeassistant.ritter.family` →
   **Sign in with Keycloak** on the login screen → realm login as `bene`
   → back in HA, signed into the **existing admin account**: dashboards,
   devices, entities intact. (If a new empty user appeared instead:
   delete it in Settings → People, re-check the username match in step 1,
   and retry while linking is still on — existing links persist, so no
   other step changes.) ✅ Landed in the existing admin account
   2026-11-10 (confirmed by operator).
3. Companion app sanity check: open the app on the phone — the existing
   session (refresh token) connects as before; SSO never touches it. A
   *fresh* app login also works via the OIDC flow (v1.2.0 fixed the
   mobile login path; the "Login with alternative method" escape hatch
   reaches the password form). ✅ Confirmed 2026-11-10: the app kept its
   session via the username/password flow (`homeassistant` provider
   refresh tokens), no re-login needed.
4. **Automatic user linking:** kept **on** by decision (2026-11-10,
   recorded above) — the second household account still needs its realm
   user. Disable it once that user has linked once.

Stage gate: Parts B and C end when 2 has passed (✅). Until then the
password form works and nothing is locked out — that property is
permanent here: password login stays enabled by design.

## Verification (final state)

```bash
# gatus stays green with SSO enabled: HA serves 200 on / unauthenticated
# (SPA shell; the SSO redirect happens in frontend JS, after the curl)
curl -s -o /dev/null -w '%{http_code}\n' https://homeassistant.ritter.family/
# expected: '200'

# SSO end-to-end (client probe; Part A's shape):
curl -s -o /dev/null -w '%{http_code}\n' \
  "https://account.ritter.family/realms/homelab/protocol/openid-connect/auth?client_id=homeassistant&response_type=code&redirect_uri=https%3A%2F%2Fhomeassistant.ritter.family%2Fauth%2Foidc%2Fcallback&scope=openid&state=probe"
# expected: '302' — Keycloak accepted client + redirect URI (the browser
# flow carries the PKCE challenge)
```

In the browser: login screen shows **Sign in with Keycloak** beside the
password form; the SSO button lands in the admin account; the companion
app still connects; gatus shows "Home Assistant" green.

## Known effects

- **SSO works from the public FQDN only.** hass-oidc-auth builds the
  redirect URI from the request origin; logging in at the raw LAN address
  (`http://192.168.20.234:8123`) sends an origin Keycloak rejects. That
  path keeps working via the local password login — which is the
  break-glass for a down proxy *and* the reason the FQDN-only SSO caveat
  costs nothing (same acceptance as PVE and Beszel).
- **Password login remains** (deliberate, see Chosen approach). The
  household sees two login options; the local admin is the break-glass
  when srv-prod-1 is unreachable.
- **Keycloak downtime blocks SSO logins** (~15–30 s restart window per
  srv-prod-1 switch; full outages until it returns). Local password
  login and existing sessions (web and companion app) are unaffected.
- **HACS updates restart HA.** Integration updates arrive through HACS
  and apply on restart — a brief outage per update, tolerated by the
  gatus 5m check. Core HA updates can in principle break the integration
  (it is a custom component); upstream minimizes core patching for
  exactly that reason, and the gatus check is the detection.
- **SSO depends on the cross-VLAN firewall policy.** HA's OIDC calls
  (discovery at setup, token exchange at every login) ride the
  `unifi_firewall_policy.homeassistant_to_directions` rule (Smart Home
  → directions :443). It is tofu-managed and references
  `unifi_client.directions.fixed_ip`, so a directions IP change updates
  it automatically on the next apply — unlike HA's UI-stored
  `trusted_proxies`, which needs the manual fix documented in the
  2026-11-02 incident.
- **No secret exists to rotate.** The client is public; if it is ever
  switched to confidential, seed both stores like Beszel's client (sops
  `secrets.json` + device `secrets.yaml` via `!secret`) — and note that
  the device copy then has no git source of truth (the reason this plan
  chose public).
- **The trusted-proxy dependency is unchanged but load-bearing.** If
  `directions`' IP ever changes, HA rejects all proxied traffic with 400
  again (the 2026-11-02 incident) — SSO included; the guardrails (tofu
  comment on `unifi_client.directions` + gatus check + UI path) cover it.
- **Unknown realm users get fresh unprivileged HA users** (identity
  provisioning defaults; the linking flag only governs *matching*
  identities, and it is off after Part C). HA's own user model is the
  gate — new users are non-admin until promoted. The realm is
  admin-provisioned, so today only `bene` exists.
- **HA-as-OAuth-provider is untouched.** Companion apps, Music Assistant
  and similar clients authenticate against HA's own OAuth2 endpoints;
  the integration is RP-only and does not sit in those flows.

## Rollback

- Part C is not a deployment: nothing to roll back (un-linking is
  possible in Settings → People by removing the SSO credential from the
  user).
- Part B: Settings → Devices & Services → OpenID Connect/SSO
  Authentication → Delete; the SSO button disappears. The HACS
  integration can be removed via HACS, or stay (inert without config).
  Local login was never off.
- Part A: `git revert` + pipeline apply deletes the client. Either side
  alone is inert: a client without the integration logs nobody in, the
  integration without a client fails logins at the Keycloak step (local
  login unaffected).

## References searched

Changed:

- `tofu/keycloak/client-homeassistant.tf` — new: the `homeassistant` OIDC
  client (Part A, public + PKCE S256)
- `tofu/network/firewall_policies.tf` — new:
  `unifi_firewall_policy.homeassistant_to_directions` — the Smart Home →
  directions :443 route for the discovery/token calls (inter-VLAN
  default-deny; mirrors the `directions_to_pve` client-to-IP pattern)
- `tofu/keycloak/secrets.json` — **deliberately unchanged**: public
  client, no secret to seed
- `docs/plans/keycloak-sso-rollout.md` — Home Assistant row: correct the
  "Native" marking (no core OIDC; HACS `hass-oidc-auth`), link this plan
- `docs/homelab.md` — new "### Home Assistant" subsection under "Manual
  setup" (added with Part 1; describes the click-ops result)

Deliberately unchanged, with reasons:

- **`modules/hosts/directions/services/https-proxy.nix`** — the
  `homeassistant.ritter.family` vhost already proxies `:8123` with
  `proxyWebsockets = true`; `recommendedProxySettings` sends
  `X-Forwarded-Proto/Host`, which is what makes the integration build
  `https` redirect URIs (upstream issue #58 is exactly the missing-
  header failure mode).
- **`modules/nixos/gatus.nix`** — HA serves `200` on `/` unauthenticated
  (SPA shell; auth happens via the API, and the SSO redirect is
  frontend JS after load). The check stays green with SSO on — no
  health-endpoint exemption needed (the rollout plan's open question
  answers itself for this service).
- **`modules/nixos/homepage.nix`** — tile and URL unchanged.
- **DNS (`tofu/dns`)** — `homeassistant.ritter.family` exists via the
  global wildcard → directions; no new record.
- **`.github/workflows`** — the `OpenTofu Keycloak` and `OpenTofu
  Network` pipelines (keys on `tofu/keycloak/**` and `tofu/network/**`)
  pick the client and firewall files up automatically.
- **`.sops.yaml` / `tofu/.sops.yaml`** — no new secret stores; no sops
  change.
- **Keycloak realm config** — no groups/roles (UI config has no roles;
  none needed for one admin), no flow changes; `preferred_username`
  comes with the default profile scope.
- **HA device files** — none exist in this repo (config-git plan
  rejected); the click-ops is recorded in `docs/homelab.md` instead.

Upstream sources consulted:

- `christiaangoossens/hass-oidc-auth`: README, `docs/configuration.md`
  (options table: PKCE default on, `features.automatic_user_linking`,
  `features.require_existing_user`, `features.default_redirect`,
  public-client recommendation), `docs/provider-configurations/keycloak.md`
  (callback path, confidential vs public, groups mapper), releases
  (v1.0.0 stable 2026-04, v1.1.1 external-OAuth2 fix, v1.2.1 mobile
  login fix) — retrieved 2026-11-10.
- authentik integration guide
  (integrations.goauthentik.io/miscellaneous/home-assistant):
  "Home Assistant does not include built-in support for SSO protocols" —
  grounds the core-OIDC correction.
- Home Assistant 2026.11 release notes (auth section: auth-provider MFA
  opt-in; client-id/origin check behind trusted proxies).
- Upstream discussions #276 (username case-sensitivity in linking) and
  issue #58 (`X-Forwarded-Proto` → https redirect URI behind proxies).
- `docs/plans/archive/2026-11-03-home-assistant-config-git.md` and
  `docs/incidents/2026-11-02-home-assistant-unreachable.md` — the
  device's management model and the proxy-trust state.

## Status

- [x] Repository exploration (device model, proxy vhost, incident and
      config-git docs, tofu root, gatus/homepage entries)
- [x] Upstream research: core-OIDC correction confirmed; hass-oidc-auth
      chosen (public client, PKCE S256, UI config flow, temporary user
      linking) — recorded above
- [x] `tofu/keycloak/client-homeassistant.tf` prepared:
      `tofu fmt -check` exit 0, `tofu validate` Success (2026-11-10)
- [x] Part A: PR merged, pipeline applied the client — probe answers the
      PKCE-error 302 (verified 2026-11-10, negative controls 400/400;
      results recorded in Part A)
- [x] Firewall route found missing during review (Smart Home → Servers
      is default-deny; no policy covered it) —
      `unifi_firewall_policy.homeassistant_to_directions` added to
      `tofu/network/firewall_policies.tf`, applied by the
      `OpenTofu Network` pipeline
- [x] Part B (2026-11-10): HACS + integration installed, UI config flow
      completed with linking on — the flow validated the discovery URL
      and the first SSO login completed, which end-to-end proves the
      device→directions→Keycloak route works
- [x] Part C (2026-11-10): first SSO login landed in the existing admin
      account; external checks green (`/` → 200, client probe → 302).
      Linking kept on by decision (see Chosen approach)
- [x] Completion: `docs/homelab.md` section, rollout-table row ✅,
      archived per AGENTS.md

## Follow-ups

- **Provision the second household realm user** (tofu `keycloak_user` in
  `users.tf`, password via console or forgot-password mail — the recipe
  referenced in the users.tf header). Her first SSO login then lands in
  her existing HA account via linking.
- **Disable automatic user linking** once that account has linked once
  (integration → Reconfigure → user-linking screen). Until then the
  username-match footgun applies to *first-time* realm identities only;
  the realm is admin-provisioned with registration off.
- ✅ Companion app sanity check (2026-11-10): the app kept its session
  via the username/password flow (`homeassistant` provider refresh
  tokens), no re-login needed — see Part C step 3.
