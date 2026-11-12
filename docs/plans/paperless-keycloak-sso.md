# Paperless-ngx: Keycloak SSO (next native client)

**Status:** planning (2026-11-12) — part of
[`keycloak-sso-rollout.md`](keycloak-sso-rollout.md) (step 2, the
Office/Media batch, "one client file at a time"). Client conventions
follow the Forgejo, PVE and Beszel onboardings; app-side staging follows
Beszel's three-part pattern (SSO beside password login → first SSO login
→ password login off). Claims marked **verified (2026-11-12)** were
checked against the live services and the pinned nixpkgs while writing
this plan.

## Background

Paperless-ngx runs on srv-prod-2 behind `https://documents.ritter.family`
(`modules/nixos/paperless.nix` — nixpkgs module, local PostgreSQL, media
on the NFS mount, `services.https-proxy` vhost with the
`documents.srv-prod-2.ritter.family` fqdn and the public alias).

SSO facts (verified against the pinned nixpkgs and upstream docs):

- The pinned nixpkgs (rev `4fe25e12`) ships **Paperless-ngx 3.3.4** with
  django-allauth bundled (socialaccount + mfa extras). SSO is configured
  **entirely via environment variables** since 2.5 — no paste-into-UI
  step like Beszel/PocketBase:
  - `PAPERLESS_APPS=allauth.socialaccount.providers.openid_connect`
    activates allauth's generic OIDC provider;
  - `PAPERLESS_SOCIALACCOUNT_PROVIDERS=<json>` carries the provider
    block (client id/secret, discovery URL, PKCE, token auth method).
- allauth's OIDC provider **sends PKCE only when enabled**
  (`OAUTH_PKCE_ENABLED`, default off) — the plan turns it on, so the
  realm-wide PKCE S256 enforcement holds.
- **No e-mail auto-linking:** paperless does not expose allauth's
  `SOCIALACCOUNT_EMAIL_AUTHENTICATION`, so an SSO identity that matches
  no linked social account does **not** link into an existing local
  account by e-mail. The pre-existing account must connect the identity
  itself — via *My Profile → connect social account* while logged in
  with the local password. This is the rollout table's "admin account
  needed for first login".
- **Auto-create exists and defaults on:** `SOCIALACCOUNT_ALLOW_SIGNUPS`
  defaults to true — every realm user self-creates an unprivileged
  account on first SSO login. Safe for the same reason as Stirling's
  `autoCreateUser`: the realm has registration off and exactly two
  admin-provisioned users (`bene`, `alina`), making the userbase an
  allow-list (`tofu/keycloak/README.md` → "Restricting who can use a
  client").
- **Regular login can be disabled declaratively** via
  `PAPERLESS_DISABLE_REGULAR_LOGIN` — and per upstream docs it only
  removes the *frontend* password form: the **Django admin at `/admin/`
  keeps accepting local credentials** (the break-glass door) and **API
  token authentication is untouched** (mobile clients and scripts never
  route through SSO).

What SSO does **not** touch:

- **Ingest** — the consumption dir, e-mail account polling and API
  uploads run user-independent; only the web UI authenticates.
- **API clients** — the API's own auth forms (basic, session and DRF
  token auth, incl. the `/api/token/` acquisition endpoint) keep working
  after `PAPERLESS_DISABLE_REGULAR_LOGIN`, by upstream guarantee
  ("does not disable ... logging in with local credentials via the
  API").
- **Gatus** (`modules/nixos/gatus.nix`) monitors
  `https://documents.ritter.family/accounts/login/` — **verified
  (2026-11-12)**: that page is allauth's login view, public, `200`
  today, and it still renders (`200`) once SSO is on, password form
  hidden, Keycloak button shown. The rollout plan's "exclude the health
  endpoint from SSO" question answers itself for this service: the
  check stays where it is.

## Chosen approach

The Keycloak side is tofu-managed like every client: one file per client
(`tofu/keycloak/client-paperless.tf`), confidential client,
authorization-code flow with PKCE S256 **enforced** — this one is safe
to enforce (unlike Stirling, where the app could not send challenges)
because the app config enables allauth's PKCE support in the same
rollout. The client secret is operator-generated and seeded into both
sops stores (`tofu/keycloak/secrets.json` for the pipeline,
srv-prod-2's `secrets.yaml` for the app), so both sides match by
construction — the Forgejo pattern, not the PocketBase paste.

**Where the secret lives on the app side:** the provider block is a
single JSON env var with the secret inside it, and the module renders
`settings` into the world-readable systemd unit file. So the whole
`PAPERLESS_SOCIALACCOUNT_PROVIDERS` value goes into a sops **template**
(`paperless/sso.env`) fed to the module's `environmentFile` option — the
module-sanctioned secrets path (same one its own docs use for
`PAPERLESS_DBPASS`). Nothing secret lands in `settings`.

**User mapping:** the local superuser is `admin` (module default; the
password is sops `paperless/admin-password`). The realm `bene` links
onto that existing account via the My-Profile connect flow (the Home
Assistant pattern: SSO identity rides the local admin), keeping the
document archive, superuser rights and API tokens intact. `alina`
self-creates an unprivileged account (own document space) on her first
SSO login — the rollout plan's auto-create end state. Keeping
`SOCIALACCOUNT_AUTO_SIGNUP` at its default `false` in stage 1 is
deliberate: with auto-signup on, bene's *premature* click on the SSO
button would silently create a stray second account instead of leaving
the linking to the connect flow (the Forgejo plan's trap).

**Password login is disabled in stage 3** via
`PAPERLESS_DISABLE_REGULAR_LOGIN = true` — same pros/cons as Beszel's
Part C (no second phishable credential; reversible by removing one env
line; authentication then depends on Keycloak on srv-prod-1 being up).
Paperless-specific break-glass: the Django admin at `/admin/` keeps
local-credential login even with regular login disabled (upstream
guarantee), so the sops admin password stays a working key at all times.

Staging:

| Stage | What | Where |
| --- | --- | --- |
| 0 | Generate + seed secrets | operator command (Part A) |
| 1 | tofu client (S256 enforced) | PR 1 (pipeline applies) |
| 2 | Stage-1 env: SSO button beside password; rate-limit proxy config | PR 2 (comin switches srv-prod-2) |
| 3 | Click-ops: connect admin account, first SSO login | Part D, operator (~5 min) |
| 4 | Part E: password login off | PR 3 |
| 5 | Completion | docs/homelab.md, sso.md + rollout table, archive |

Order constraint: **PR 1 must land before PR 2** — Keycloak enforces
S256 from the moment the client exists, so if the SSO button deployed
first, logins would fail at Keycloak with "Missing parameter:
code_challenge_method" (the failure mode the Forgejo probe
demonstrated). While only PR 1 is applied, the app has no SSO button at
all and nothing user-visible changes.

## Part A — secret seeding (operator, before PR 1; not idempotent — `sops set` overwrites)

The tofu pipeline reads `paperless_client_secret` at plan time, so the
sops stores must hold the values before PR 1 can plan. Run from the repo
root on framework-13 (the age identity is not available in CI or
sandbox sessions — same caveat as the Beszel/Stirling seedings):

```bash
unset CLIENT_SECRET
# generate e.g. with: head -c 24 /dev/urandom | base64 | tr -d '/+='
read -rs -p "paperless client secret: " CLIENT_SECRET; echo
printf '%s' "$CLIENT_SECRET" | jq -R . | \
  sops set tofu/keycloak/secrets.json '["paperless_client_secret"]' --value-stdin
printf '%s' "$CLIENT_SECRET" | jq -R . | \
  sops set modules/hosts/srv-prod-2/secrets.yaml '["paperless"]["keycloak-client-secret"]' --value-stdin
unset CLIENT_SECRET
```

Nested path under the existing `paperless:` mapping (the dashed-key form
the Forgejo plan settled on). Equality check across the two stores (no
output, exit 0 = byte-identical; ciphertexts differ because each
encryption mints fresh IVs):

```bash
diff <(sops -d --extract '["paperless_client_secret"]' tofu/keycloak/secrets.json | sha256sum) \
     <(sops -d --extract '["paperless"]["keycloak-client-secret"]' modules/hosts/srv-prod-2/secrets.yaml | sha256sum)
```

## Part B — tofu client (PR 1)

Full content of the new file (one file per client, per the convention):

```diff
@@ tofu/keycloak/client-paperless.tf @@
+# One OIDC client per service, one file per client.
+resource "keycloak_openid_client" "paperless" {
+  realm_id  = keycloak_realm.homelab.id
+  client_id = "paperless"
+  name      = "Paperless-ngx"
+  enabled   = true
+
+  access_type                  = "CONFIDENTIAL"
+  standard_flow_enabled        = true
+  direct_access_grants_enabled = false
+  # allauth's OIDC provider sends PKCE only when the app config enables
+  # it (default off) — the paperless module sets `oauth_pkce_enabled`
+  # (see docs/plans/paperless-keycloak-sso.md, Part C), so S256 is
+  # enforced here like on every other client. Land this PR before the
+  # stage-1 module change (PR 2), or the deployed button would fail
+  # Keycloak's challenge check.
+  pkce_code_challenge_method = "S256"
+
+  # Operator-generated and seeded into both sops stores (tofu's
+  # secrets.json for the pipeline, srv-prod-2's yaml for the app's env
+  # template) so the two sides match by construction. Seeding command:
+  # docs/plans/paperless-keycloak-sso.md, Part A.
+  client_secret = data.sops_file.secrets.data["paperless_client_secret"]
+
+  # allauth derives the callback from the request origin plus the fixed
+  # path /accounts/oidc/<provider_id>/login/callback/ (provider_id
+  # "keycloak", set in the app config). Logins opened at the aspect
+  # vhost (documents.srv-prod-2.ritter.family) would send a different
+  # origin and fail Keycloak's redirect check — the public FQDN is the
+  # one supported entry point (same caveat as PVE, Beszel, Stirling).
+  valid_redirect_uris = [
+    "https://documents.ritter.family/accounts/oidc/keycloak/login/callback/",
+  ]
+}
```

The `OpenTofu Keycloak` pipeline plans on the PR and applies on merge.
Check after merge, from the public side:

```bash
curl -s "https://account.ritter.family/realms/homelab/protocol/openid-connect/auth?client_id=paperless&response_type=code&redirect_uri=https%3A%2F%2Fdocuments.ritter.family%2Faccounts%2Foidc%2Fkeycloak%2Flogin%2Fcallback%2F&scope=openid&state=probe" -o /dev/null -w '%{http_code}\n'
# expected: '302' — Keycloak accepted client + redirect URI (same probe
# as the Beszel/Stirling plans; the browser flow carries the extras).
# Verified (2026-11-12): answers '400' (Client not found) before the
# client exists, so the probe also proves the apply.
```

Stage gate: the probe must answer `302` before PR 2 lands.

## Part C — stage-1 code: SSO beside password (PR 2)

The SSO wiring goes into the **generic `paperless` aspect itself** — the
same cut the earlier native onboardings chose (forgejo, stirling-pdf):
the aspect already hardcodes the public FQDN (`PAPERLESS_URL`, proxy
alias), and srv-prod-2's instance file only adds storage/backup wiring.
So `modules/hosts/srv-prod-2/configuration.nix` stays untouched.

**Verified (2026-11-12):** this diff was applied to a scratch checkout
and evaluated against the real srv-prod-2 config —
`environmentFile` renders to
`/run/secrets/rendered/paperless/sso.env`, the web unit's
`EnvironmentFile` picks it up next to the secret-key file, the unit
environment carries `PAPERLESS_APPS`, and the rendered template content
is the single JSON line below with the sops placeholder spliced in
(the multi-line interpolation is nixfmt formatting; the string value
stays one line, as `systemd`'s EnvironmentFile requires).

```diff
@@ modules/nixos/paperless.nix @@
 _: {
   flake.modules.nixos.paperless =
     { config, ... }:
     {
       sops.secrets."paperless/admin-password" = { };
+      sops.secrets."paperless/keycloak-client-secret" = { };
+
+      # Keycloak SSO (docs/plans/paperless-keycloak-sso.md): the allauth
+      # provider block carries the client secret inside its JSON, and
+      # `settings` renders into the world-readable systemd unit file —
+      # so the whole PAPERLESS_SOCIALACCOUNT_PROVIDERS value lives in
+      # this sops template, fed to the module's environmentFile (the
+      # same path its docs use for PAPERLESS_DBPASS). A rotation
+      # restarts the web service, which reads the env at start.
+      sops.templates."paperless/sso.env" = {
+        restartUnits = [ "paperless-web.service" ];
+        # Single line — systemd EnvironmentFile values must not span
+        # lines. The placeholder resolves at runtime to the sops secret
+        # "paperless/keycloak-client-secret".
+        content = ''
+          PAPERLESS_SOCIALACCOUNT_PROVIDERS={"openid_connect":{"OAUTH_PKCE_ENABLED":true,"APPS":[{"provider_id":"keycloak","name":"Keycloak","client_id":"paperless","secret":"${
+            config.sops.placeholder."paperless/keycloak-client-secret"
+          }","settings":{"server_url":"https://account.ritter.family/realms/homelab/.well-known/openid-configuration","oauth_pkce_enabled":true,"token_auth_method":"client_secret_basic"}}]}}
+        '';
+      };
 
       services.paperless = {
         enable = true;
         port = 28981; # default; referenced by the proxy target below
         database.createLocally = true; # use the local postgres already running on this host
         passwordFile = config.sops.secrets."paperless/admin-password".path;
+        environmentFile = config.sops.templates."paperless/sso.env".path;
         settings = {
           PAPERLESS_URL = "https://documents.ritter.family"; # required for CSRF/redirects behind proxy
           PAPERLESS_TIME_ZONE = "Europe/Berlin";
           PAPERLESS_OCR_LANGUAGE = "deu+eng"; # nixpkgs module auto-builds tesseract5 with these langs
+
+          # Stage 1 (docs/plans/paperless-keycloak-sso.md): activate the
+          # django-allauth OIDC provider; the provider block itself
+          # (client id/secret, discovery URL, PKCE) comes from the sops
+          # environmentFile. With regular login still on, this only adds
+          # a "Sign in with Keycloak" button beside the password form.
+          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
+          # v3 allauth derives the rate-limited client IP from
+          # X-Forwarded-For and trusts zero proxies by default —
+          # trust exactly the one nginx hop on localhost, or all logins
+          # share the proxy's single rate-limit bucket
+          # (https://docs.paperless-ngx.com/migration-v3/).
+          PAPERLESS_TRUSTED_PROXIES = "127.0.0.1,::1";
         };
       };
```

Provider-block details worth their comments in review:

- `oauth_pkce_enabled: true` (plus the provider-global
  `OAUTH_PKCE_ENABLED`) makes allauth send S256 challenges, matching the
  client's enforcement from PR 1.
- `token_auth_method: "client_secret_basic"` is pinned preemptively —
  the paperless v3 migration notes name a callback `invalid_client`
  when the IdP and allauth disagree on the token endpoint auth method;
  Keycloak advertises and accepts `client_secret_basic`.
- `SOCIALACCOUNT_ALLOW_SIGNUPS` keeps its default `true` (realm
  allow-list reasoning, see Background) and
  `SOCIALACCOUNT_AUTO_SIGNUP` keeps its default `false` (linking happens
  in Part D, not by premature signup) — both only flipped deliberately,
  never by accident of omission.

```bash
nix flake check && nix fmt   # gate before opening the PR
```

Merge; comin switches srv-prod-2 and paperless-web restarts with the
provider env. Verify:

```bash
# the app still boots (a malformed provider JSON fails loudly at startup)
ssh root@srv-prod-2.ritter.family 'journalctl -u paperless-web --since "-5min" --no-pager | tail -n 20'

# the login page now offers Keycloak beside the password form (UI check)
curl -s -o /dev/null -w '%{http_code}\n' https://documents.ritter.family/accounts/login/
# expected: '200' — gatus stays green throughout
```

Stage gate: do not proceed to Part D before the button is visible and
the web unit is healthy.

## Part D — click-ops: link the admin account (operator, ~5 min; the stage gate)

Ordered so the password door stays open the whole time:

1. Sign in at `https://documents.ritter.family` with username `admin`
   and the sops `paperless/admin-password`
   (`sops -d --extract '["paperless"]["admin-password"]'
   modules/hosts/srv-prod-2/secrets.yaml`).
2. User dropdown → **My Profile** → connect the social account →
   **Keycloak** → complete the realm flow as `bene` → back on the
   profile page, the Keycloak identity shows as connected.
   - Contingency: if allauth refuses the connect because the e-mail is
     claimed by another local record, set the admin profile's e-mail to
     the realm `bene` address first (there is no second local user).
3. Log out. Sign in again via **Sign in with Keycloak** → the session
   lands in the `admin` account: full document archive, superuser
   rights, API tokens intact.
4. Do **not** complete a "sign up" confirmation form along the way —
   linking goes through My Profile (step 2). If a stray auto-created
   account appears anyway, delete it in the Django admin at
   `/admin/` (local credentials) before proceeding.

Stage gate: do not proceed to Part E until 3 has passed — with password
login off, the sole web door must already be the realm identity.

## Part E — password login off (PR 3)

```diff
@@ modules/nixos/paperless.nix @@
           # Stage 1 (docs/plans/paperless-keycloak-sso.md): activate the
           # django-allauth OIDC provider; the provider block itself
           # (client id/secret, discovery URL, PKCE) comes from the sops
           # environmentFile. With regular login still on, this only adds
           # a "Sign in with Keycloak" button beside the password form.
           PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
+          # Stage 3: SSO is the only door on the web UI. Break-glass: the
+          # Django admin at /admin/ still accepts the local admin
+          # credentials (upstream guarantee), and removing this line
+          # restores the password form on the next switch. See the plan's
+          # Rollback section.
+          PAPERLESS_DISABLE_REGULAR_LOGIN = true;
           # v3 allauth derives ...
```

Merge; comin switches srv-prod-2; the password form disappears from
`/accounts/login/` while Keycloak SSO keeps working. The
`paperless/admin-password` sops secret deliberately **stays** — it is
the break-glass credential (usable at `/admin/` even without the env
flip).

Optional, after a soak period: `PAPERLESS_REDIRECT_LOGIN_TO_SSO = true`
sends users straight into the realm flow (JS redirect, same shape as
Stirling's deferred `SECURITY_SSOAUTOLOGIN`).

## Verification (final state)

```bash
# password sign-in is gone; /accounts/login/ renders only the Keycloak
# button (UI check — upstream exposes no config endpoint for this)

# gatus stays green with SSO enabled (login page is public by design):
curl -s -o /dev/null -w '%{http_code}\n' https://documents.ritter.family/accounts/login/
# expected: '200'

# SSO end-to-end (client probe; same shape as Beszel/Stirling):
curl -s "https://account.ritter.family/realms/homelab/protocol/openid-connect/auth?client_id=paperless&response_type=code&redirect_uri=https%3A%2F%2Fdocuments.ritter.family%2Faccounts%2Foidc%2Fkeycloak%2Flogin%2Fcallback%2F&scope=openid&state=probe" -o /dev/null -w '%{http_code}\n'
# expected: '302'
```

## Known effects

- **Auth dependency:** with Part E, logging into the web UI requires
  Keycloak (srv-prod-1) up. Break-glass: flip
  `PAPERLESS_DISABLE_REGULAR_LOGIN` back (env line, redeploy), or use
  the Django admin at `/admin/`, which keeps local-credential login by
  upstream guarantee. `/admin/` is reachable through the public vhost —
  deliberate: it *is* the break-glass, and allauth rate-limits it
  (Part C's trusted-proxy config makes those limits per-client).
- **API/mobile clients unaffected:** DRF token auth and basic auth
  never route through SSO; `PAPERLESS_DISABLE_REGULAR_LOGIN` only
  removes the frontend password form (upstream docs).
- **Second household user:** `alina` self-provisions an unprivileged
  account on her first SSO login (default confirmation form; flip
  `PAPERLESS_SOCIAL_AUTO_SIGNUP = true` later for the one-click path).
  Every realm user can get a seat — the realm's two admin-provisioned
  users are the allow-list.
- **Logout scope:** signing out ends the paperless session only, not
  the realm SSO session — same as every service onboarded so far.
- **Rotation:** the client secret lives in two sops stores and the
  rendered template; rotate with `sops set` on both (Part A command),
  `restartUnits` restarts paperless-web on the template re-render, and
  the pipeline apply mirrors the value into Keycloak.
- **Paperless restarts on the switch:** PR 2 and PR 3 bounce
  paperless-web for a few seconds (normal comin activation); ingest and
  scheduled tasks resume automatically.

## Rollback

Per part, each restores the previous state on its own:

- **Part E:** remove the `PAPERLESS_DISABLE_REGULAR_LOGIN` line,
  redeploy — the password form returns. (No self-pinning settings file
  like Stirling's `settings.yml`: paperless reads env at boot and
  writes no auth config back, so the env revert is complete.)
- **Part D:** disconnect the social account (My Profile, or Django
  admin → Social accounts). Not a deployment; nothing to roll back
  otherwise.
- **Part C:** revert the module diff; comin switches back — the SSO
  button disappears, password login alone remains. Delete the sops
  entries if desired (`sops unset`; not idempotent, errors when the key
  is gone).
- **Part B:** set `enabled = false` in `client-paperless.tf` and apply,
  or revert the PR — the pipeline apply **deletes the client**
  (state-based, like Forgejo). Part A's values can stay (unused secret,
  no harm).
- **Part A:** no undo needed; the end state is "values exist", and
  re-running overwrites them.

## Places that need no change (checked, with reasons)

- **`modules/hosts/srv-prod-2/configuration.nix`** — the SSO wiring
  lands inside the generic `paperless` aspect (already a singleton that
  hardcodes its FQDN, like `stirling-pdf`); no import-list change and no
  new `-on-<host>` instance.
- **`modules/hosts/srv-prod-2/services/paperless.nix`** — NFS mount,
  unit mount-gates and restic backups are auth-independent. The
  social-account rows live in the paperless PostgreSQL database, which
  the existing restic backup already dumps (`pg_dump` in
  `backupPrepareCommand`) — SSO state is backed up from day one.
- **`modules/nixos/https-proxy`** — the vhost uses
  `recommendedProxySettings` (`X-Forwarded-For/Proto` set), which is
  exactly what Part C's `PAPERLESS_TRUSTED_PROXIES` declares; no proxy
  change.
- **DNS (`tofu/dns`)** — `*.ritter.family` wildcard; no new record.
- **Homepage tile** (`modules/nixos/homepage.nix`) — URL and icon
  unchanged.
- **`PAPERLESS_URL` / CSRF** — already set; allauth's login flow rides
  the same trusted origin.
- **Gatus** — check target `/accounts/login/` stays public and `200`
  through every stage (verified 2026-11-12 for the current state; the
  allauth login view renders with regular login disabled).
- **`docs/sso.md` / rollout table / `docs/homelab.md`** — updated at
  completion only (Cleanup), matching the Beszel/Stirling flow.

## Cleanup / follow-ups

- [ ] Update the Paperless-ngx row in
      [`keycloak-sso-rollout.md`](keycloak-sso-rollout.md) to ✅, add the
      Paperless row to `docs/sso.md`'s "Services with SSO enabled"
      table, and archive this plan with `git mv` to
      `docs/plans/archive/YYYY-MM-DD-paperless-keycloak-sso.md` per
      AGENTS.md.
- [ ] `docs/homelab.md`: add the Paperless recital (env-only SSO
      wiring, sops keys, `/admin/` break-glass, secret-rotation
      runbook).
- [ ] After a soak period: `PAPERLESS_REDIRECT_LOGIN_TO_SSO = true`
      (straight-to-Keycloak login page).
- [ ] When `alina` first logs in: decide on
      `PAPERLESS_SOCIAL_AUTO_SIGNUP = true` (one-click self-provision)
      vs. the confirmation-form default.
- [ ] Optional hardening, unprioritized: block `/admin/` for non-LAN
      sources at the proxy if the break-glass ever moves to ssh +
      env-flip only.
