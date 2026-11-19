# Immich: Keycloak SSO (next native client)

**Status:** in progress (2026-11-18) — stages 1–3 done (#373, #374):
SSO sits beside the password form and the first Keycloak logins (web +
mobile) are verified by the operator. Part E (password login off)
staged. Part of
[`keycloak-sso-rollout.md`](keycloak-sso-rollout.md) (step 2, the
Office/Media batch, "one client file at a time"). Client conventions
follow the Forgejo, PVE, Beszel, Paperless and Nextcloud onboardings;
app-side staging follows Beszel's three-part pattern (SSO beside password
login → first SSO login → password login off). Claims marked
**verified (2026-11-18)** were checked against the live services, the
pinned nixpkgs (rev `5d2b81a7`) and the Immich source, v3.4.1 unless
noted.

## Background

Immich 3.4.1 runs on srv-prod-4 behind `https://photos.ritter.family`
(`modules/nixos/immich.nix` — nixpkgs module driving Immich's config
file, local PostgreSQL, media on the NFS mount; the instance file
`modules/hosts/srv-prod-4/services/immich.nix` adds the NFS data dir and
its mount gate). The edge proxy on directions maps the public FQDN to
the aspect vhost (`photos.ritter.family` →
`https://photos.srv-prod-4.ritter.family`, websockets, 50 GB bodies,
600 s timeouts — `modules/hosts/directions/services/https-proxy.nix`).

SSO facts (verified against the pinned nixpkgs and the Immich source):

- The pinned nixpkgs ships **Immich 3.4.1**
  (`pkgs/by-name/im/immich/package.nix`). OAuth is configured through the
  `settings` config file the module renders to `/run/immich/config.json`
  (`IMMICH_CONFIG_FILE`): an `oauth` section plus a
  `passwordLogin.enabled` switch.
- **The client secret has a sanctioned secrets path in the module**: any
  `settings` value of the form `{ _secret = "/path"; }` is replaced with
  the file's contents in preStart (systemd `LoadCredential`) — the
  module's own deprecation notice names
  `services.immich.settings.oauth.clientSecret._secret` as the example.
  The SMTP credentials in this aspect already ride the same mechanism.
- **PKCE is automatic.** Immich's openid-client sends
  `code_challenge`/`code_challenge_method=S256` whenever the IdP's
  discovery document advertises PKCE support (`supportsPKCE()`,
  `server/src/repositories/oauth.repository.ts`, v3.4.1) — the realm
  advertises `code_challenge_methods_supported: ["plain", "S256"]`
  (**verified (2026-11-18)** live), so the realm-wide S256 enforcement
  holds without extra app config.
- **Auto-register defaults to on** (`oauth.autoRegister: true`,
  `server/src/dtos/config.dto.ts`): unknown realm identities
  self-create a fresh, unprivileged account on first login. Safe for the
  same reason as every onboarding so far: the realm has registration off
  and exactly two admin-provisioned users (`bene`, `alina`), making the
  userbase an allow-list (`tofu/keycloak/README.md` → "Restricting who
  can use a client").
- **E-mail auto-linking is built in** (unlike paperless): the callback
  looks the identity up by `sub` first, then falls back to
  `getByEmail(profile.email)` and stamps `oauthId` onto the existing
  account (`server/src/services/auth.service.ts`, `callback()`); a
  conflict (e-mail already linked to another account) is rejected. So
  realm `bene` links onto the existing local account **provided the
  local account's e-mail matches the realm e-mail** — that check is the
  one click-op in Part D.
- **The realm delivers no `immich_role` claim** (default `roleClaim`):
  an absent claim leaves the role untouched, and new users register
  non-admin — admin status stays Immich-side, nobody is promoted from a
  token.
- **Password login is disabled declaratively** via
  `passwordLogin.enabled = false`: `login()` then throws
  `UnauthorizedException('Password login has been disabled')` before any
  credential check (`auth.service.ts:62`). That kills the web password
  form **and the mobile app's password login** — re-logins go through
  OAuth — while API-key authentication (scripts, `immich-go`,
  `immich-cli`) and existing sessions are untouched.
- **The config file is the single source of truth:** with
  `IMMICH_CONFIG_FILE` in use, the admin UI refuses to save system
  settings ("Cannot update configuration while IMMICH_CONFIG_FILE is in
  use", `server/src/services/system-config.service.ts`) and the DB-stored
  config is ignored (`server/src/utils/config.ts`, `buildConfig()`).
  Click-ops can *not* shadow the declarative OAuth/password-login state;
  flips go through the module. User management (accounts, e-mails,
  quotas) is separate and keeps working in the UI.
- **Logout ends the realm session** (upstream default): for OAuth
  sessions Immich redirects the browser to the IdP's
  `end_session_endpoint` from discovery, carrying `id_token_hint`
  (`getLogoutEndpoint`, `auth.service.ts`) — the realm advertises
  `https://account.ritter.family/realms/homelab/protocol/openid-connect/logout`
  (**verified (2026-11-18)** live). Keycloak shows its logout
  confirmation page, then the realm session is gone. A deliberate
  difference from Forgejo/PVE/Beszel/Paperless (their logout ends only
  the app session); same spirit as Nextcloud's single logout.
- **Mobile OAuth rides a custom scheme**: the app's redirect URI is
  `app.immich:///oauth-callback` (docs: "You MUST include this for iOS
  and Android mobile apps to work properly"); the app carries state and
  PKCE verifier in the callback body (cookies are unavailable there).
  Immich also ships `/api/oauth/mobile-redirect` as an https workaround
  plus a `mobileRedirectUri` override — not needed while Keycloak
  accepts the custom scheme.

What SSO does **not** touch:

- **Uploads and background jobs** — mobile backup sessions, API-key
  scripts, machine learning and storage templates never route through
  the login page; only new logins do.
- **API keys** — `x-api-key` authentication is independent of
  `passwordLogin` (it never calls `login()`); CLI tooling keeps working
  after Part E.
- **Gatus** (`modules/nixos/gatus.nix`) monitors
  `https://photos.ritter.family/api/server/ping` — **verified
  (2026-11-18)**: public, answers `200` `{"res":"pong"}` today, and it
  is not an auth-gated route. The rollout plan's "exclude the health
  endpoint from SSO" question answers itself for this service: the
  check stays where it is.
- **Notifications SMTP** — Brevo relay keeps sending account e-mails.
  Note that SSO users have no local password, so password-reset mails
  become moot for them; invited-user mails still make sense.

## Chosen approach

The Keycloak side is tofu-managed like every client: one file per client
(`tofu/keycloak/client-immich.tf`), confidential client,
authorization-code flow with PKCE S256 enforced (safe here — Immich
sends challenges whenever the IdP advertises them, verified in source
and discovery). The client secret is operator-generated and seeded into
both sops stores (`tofu/keycloak/secrets.json` for the pipeline,
srv-prod-4's `secrets.yaml` for the app), so both sides match by
construction — the Forgejo/Paperless/Nextcloud pattern.

**Where the wiring lives on the app side:** the generic `immich` aspect
itself — the same cut as paperless/stirling: the aspect already
hardcodes the public FQDN (`server.externalDomain`) and is a singleton
imported only by srv-prod-4 via `immich-on-srv-prod-4`; the instance
file stays untouched.

**User mapping:** realm `bene` links onto the existing local account by
e-mail (built-in auto-link, Forgejo-style) — Part D first checks the
local account's e-mail matches the realm e-mail, since a mismatch would
silently spawn a fresh account instead. `alina` self-creates an
unprivileged account on her first SSO login (`autoRegister` default
true) — the rollout plan's auto-create end state, effective from day
one, safe by the realm allow-list reasoning. The `immich_role` claim
never arrives, so admin status stays Immich-side.

**Password login is disabled in stage 3** via
`passwordLogin.enabled = false` — same pros/cons as Beszel's Part C (no
second phishable credential; authentication then depends on Keycloak on
srv-prod-1 being up). Break-glass: the env flip (remove the line,
redeploy) and API keys, which never route through the login page.

Staging:

| Stage | What | Where |
| --- | --- | --- |
| 0 | Generate + seed secrets | operator command (Part A) |
| 1 | tofu client (S256 enforced) | ✅ merged as #373 (probe `302`, verified post-merge) |
| 2 | Stage-1 config: SSO button beside password | ✅ merged as #374; comin switched srv-prod-4 |
| 3 | Click-ops: e-mail check, first SSO logins, mobile check | ✅ 2026-11-19 (operator) |
| 4 | Part E: password login off | PR 3 |
| 5 | Completion | docs/homelab.md, sso.md + rollout table, archive |

Order constraint: **PR 1 must land before PR 2** — Keycloak enforces
S256 from the moment the client exists, and the client probe below
answers `400` (`Client not found`) today (**verified (2026-11-18)**), so
a button deployed first would fail at Keycloak. While only PR 1 is
applied, Immich has no SSO button at all and nothing user-visible
changes.

## Part A — secret seeding (operator, before PR 1; not idempotent — `sops set` overwrites)

The tofu pipeline reads `immich_client_secret` at plan time, so the sops
stores must hold the values before PR 1 can plan. Run from the repo root
on framework-13 **outside the sandbox** (the age identity is not
available in CI or sandbox sessions — verified: `sops -d` fails here
with "failed to load age identities"; same caveat as every seeding so
far):

```bash
unset CLIENT_SECRET
# generate e.g. with: head -c 24 /dev/urandom | base64 | tr -d '/+='
read -rs -p "immich client secret: " CLIENT_SECRET; echo
printf '%s' "$CLIENT_SECRET" | jq -R . | \
  sops set tofu/keycloak/secrets.json '["immich_client_secret"]' --value-stdin
printf '%s' "$CLIENT_SECRET" | jq -R . | \
  sops set modules/hosts/srv-prod-4/secrets.yaml '["immich"]["keycloak-client-secret"]' --value-stdin
unset CLIENT_SECRET
```

Nested path under the existing `immich:` mapping in
`modules/hosts/srv-prod-4/secrets.yaml` (the dashed-key form the
Forgejo/Paperless/Nextcloud seedings settled on). Equality check across
the two stores (no output, exit 0 = byte-identical; ciphertexts differ
because each encryption mints fresh IVs):

```bash
diff <(sops -d --extract '["immich_client_secret"]' tofu/keycloak/secrets.json | sha256sum) \
     <(sops -d --extract '["immich"]["keycloak-client-secret"]' modules/hosts/srv-prod-4/secrets.yaml | sha256sum)
```

## Part B — tofu client (PR 1)

Full content of the new file (one file per client, per the convention):

```diff
@@ tofu/keycloak/client-immich.tf @@
+# One OIDC client per service, one file per client.
+resource "keycloak_openid_client" "immich" {
+  realm_id  = keycloak_realm.homelab.id
+  client_id = "immich"
+  name      = "Immich"
+  enabled   = true
+
+  access_type                  = "CONFIDENTIAL"
+  standard_flow_enabled        = true
+  direct_access_grants_enabled = false
+  # Immich's openid-client sends PKCE S256 whenever the IdP's discovery
+  # document advertises support (supportsPKCE(),
+  # server/src/repositories/oauth.repository.ts, v3.4.1 — the realm
+  # advertises S256), so S256 is enforced here like on every other
+  # client. Land this PR before the stage-1 module change (PR 2), or the
+  # deployed button would target a client that does not exist yet.
+  pkce_code_challenge_method = "S256"
+
+  # Operator-generated and seeded into both sops stores (tofu's
+  # secrets.json for the pipeline, srv-prod-4's yaml for the app's
+  # config file) so the two sides match by construction. Seeding
+  # command: docs/plans/immich-keycloak-sso.md, Part A.
+  client_secret = data.sops_file.secrets.data["immich_client_secret"]
+
+  # The web client builds the redirect_uri from its own origin:
+  # <origin>/auth/login for sign-in and <origin>/user-settings for
+  # manually linking an account (upstream docs "Prerequisites", verified
+  # against the v3.4.1 sources). The mobile app's callback is the custom
+  # scheme app.immich:///oauth-callback (required for the app's OAuth
+  # flow; the app carries state + PKCE verifier in the callback body, so
+  # no cookies are needed there). Logins opened at the aspect vhost
+  # (photos.srv-prod-4.ritter.family) would send a different origin and
+  # fail Keycloak's redirect check — the public FQDN is the one
+  # supported entry point (same caveat as every other service).
+  valid_redirect_uris = [
+    "https://photos.ritter.family/auth/login",
+    "https://photos.ritter.family/user-settings",
+    "app.immich:///oauth-callback",
+  ]
+}
```

The `OpenTofu Keycloak` pipeline plans on the PR and applies on merge.
Check after merge, from the public side:

```bash
curl -s "https://account.ritter.family/realms/homelab/protocol/openid-connect/auth?client_id=immich&response_type=code&redirect_uri=https%3A%2F%2Fphotos.ritter.family%2Fauth%2Flogin&scope=openid&state=probe" -o /dev/null -w '%{http_code}\n'
# expected: '302' — Keycloak accepted client + redirect URI (same probe
# as every plan so far; the browser flow carries the extras).
# Verified (2026-11-18): answers '400' (Client not found) before the
# client exists, so the probe also proves the apply.
```

Stage gate: the probe must answer `302` before PR 2 lands.

## Part C — stage-1 code: SSO beside password (PR 2)

The wiring goes into the generic `immich` aspect
(`modules/nixos/immich.nix`) — the singleton that already hardcodes the
public FQDN; `modules/hosts/srv-prod-4/{configuration,services/immich}.nix`
stay untouched.

```diff
@@ modules/nixos/immich.nix @@
       # SMTP credentials are bound when immich-server starts (systemd
       # loads them as credentials, preStart splices them into the config
       # file), so a rotated secret must not leave a stale process.
       sops.secrets."immich/smtp-username" = {
         restartUnits = [ "immich-server.service" ];
       };
       sops.secrets."immich/smtp-password" = {
         restartUnits = [ "immich-server.service" ];
       };
+      # Keycloak client secret for SSO
+      # (docs/plans/immich-keycloak-sso.md) — same binding as the SMTP
+      # secrets: systemd LoadCredential, spliced into
+      # /run/immich/config.json in preStart via the module's _secret
+      # mechanism; rotation restarts the server.
+      sops.secrets."immich/keycloak-client-secret" = {
+        restartUnits = [ "immich-server.service" ];
+      };
 
       services.immich = {
         enable = true;
         # see https://docs.immich.app/install/config-file
         settings = {
           server.externalDomain = "https://photos.ritter.family";
           storageTemplate.enabled = true;
+
+          # Keycloak SSO (docs/plans/immich-keycloak-sso.md, stage 1):
+          # adds a "Sign in with Keycloak" button beside the password
+          # form. Defaults left implicit (verified against the Immich
+          # 3.4.1 source, server/src/dtos/config.dto.ts): autoRegister
+          # true (auto-create on first login, safe — realm allow-list),
+          # autoLaunch false, scope "openid email profile",
+          # roleClaim "immich_role" (never present in the realm, so
+          # admin status stays Immich-side).
+          oauth = {
+            enabled = true;
+            issuerUrl = "https://account.ritter.family/realms/homelab";
+            clientId = "immich";
+            buttonText = "Sign in with Keycloak";
+            # Upstream default is client_secret_post; pinned to the
+            # fleet-proven client_secret_basic (paperless talks to the
+            # same realm with it) so the token exchange matches a
+            # known-good Keycloak interaction.
+            tokenEndpointAuthMethod = "client_secret_basic";
+            # Resolved at runtime by the module's _secret mechanism —
+            # the rendered config.json carries the sops value, never the
+            # placeholder or the store path.
+            clientSecret._secret = config.sops.secrets."immich/keycloak-client-secret".path;
+          };
           notifications.smtp = {
```

Notes for review:

- `issuerUrl` is the realm root: Immich appends
  `.well-known/openid-configuration` during discovery itself (upstream
  docs, "The `.well-known/openid-configuration` part of the url is
  optional").
- Discovery/token/JWKS requests ride the LAN split-dns record for
  `account.ritter.family` with a valid `*.ritter.family` certificate —
  no `allowInsecureRequests`, and no SSRF guard to lift (Node has none;
  paperless on srv-prod-2 does the identical fetch without one).
- While `settings` is non-null the admin UI cannot change system
  settings at all (upstream refuses updates with
  `IMMICH_CONFIG_FILE` in use) — the declaration below is authoritative,
  and stage 3's flip cannot be shadowed by click-ops.

```bash
nix flake check && nix fmt   # gate before opening the PR
```

Merge; comin switches srv-prod-4; immich-server restarts with the
rendered OAuth config. Verify:

```bash
# the server still boots (a malformed oauth block fails loudly at start)
ssh root@srv-prod-4.ritter.family 'journalctl -u immich-server --since "-5min" --no-pager | tail -n 20'

# the rendered config carries the oauth block with the real secret value
# (not the placeholder) — read as root on srv-prod-4:
ssh root@srv-prod-4.ritter.family 'jq ".oauth | del(.clientSecret)" /run/immich/config.json; \
  jq -r ".oauth.clientSecret" /run/immich/config.json | head -c 4'
# expected: enabled=true, issuer/clientId as declared; the secret starts
# with its first 4 characters and must match the seeded value

# the login page now offers Keycloak beside the password form (UI check)
curl -s -o /dev/null -w '%{http_code}\n' https://photos.ritter.family/auth/login
# expected: '200' — gatus stays green throughout (ping check unchanged)

# the password door still works exactly as before (bogus credentials)
curl -s -X POST https://photos.ritter.family/api/auth/login -H 'Content-Type: application/json' -d '{"email":"probe@example.com","password":"probe"}' -w '\n%{http_code}\n' -o /dev/null
# expected: '401' with body {"message":"Incorrect email or password"}
# (verified (2026-11-18) — today's response; stage 3 changes the body)
```

Stage gate: do not proceed to Part D before the button is visible on the
web login page and immich-server is healthy.

## Part D — click-ops: first SSO logins (operator, ~10 min; the stage gate)

Ordered so the password door stays open the whole time:

1. **E-mail check first** (the auto-link key): sign in with the local
   password, open *Account settings* (and *Administration → Users* for
   the admin) and confirm bene's e-mail equals the realm e-mail (the
   `user_bene_email` seeded in `tofu/keycloak/secrets.json`). If they
   differ, fix the Immich e-mail before the first SSO click — user
   management still works in the UI even though system settings are
   locked by the config file. A mismatch would otherwise make the first
   SSO login silently create a fresh account instead of linking.
2. Sign out (or use a private window) and open
   `https://photos.ritter.family`. Click **Sign in with Keycloak** and
   complete the realm flow as `bene` (passkey or realm password).
   Confirm the session lands in the **existing** account: same photos,
   albums, API keys, admin status (the e-mail auto-link stamped
   `oauthId` onto it).
3. Log out. Note the round-trip: Immich deletes its session and
   redirects through Keycloak's logout page, which ends the realm
   session too (upstream default, see Known effects). Sign in via
   Keycloak once more.
4. **Mobile app, before Part E removes password login:** point the app
   at `https://photos.ritter.family` (the public FQDN — not
   `photos.srv-prod-4.ritter.family:2283` or another origin, which would
   fail Keycloak's redirect check), sign out, and sign in again via the
   app's **Sign in with Keycloak** path (browser opens, custom-scheme
   `app.immich:///oauth-callback` lands back in the app). Existing
   sessions on other devices keep working regardless.
5. `alina`'s first SSO login self-creates a fresh, unprivileged account
   (storage label from `preferred_username`, unlimited quota by
   default) — the rollout plan's auto-create end state. No operator
   step unless a stray account appears.
6. Check *Administration → Users*: no account other than the known
   locals and `alina`'s self-created one should have appeared. A stray
   account for bene would mean the e-mails did not match (step 1) —
   fix the e-mail, delete the stray in the admin UI, and re-login.

Stage gate: do not proceed to Part E until steps 2 and 4 have passed —
with password login off, the web door and the mobile re-login path must
already be the realm identity.

## Part E — password login off (PR 3)

```diff
@@ modules/nixos/immich.nix @@
           oauth = {
             ...
             clientSecret._secret = config.sops.secrets."immich/keycloak-client-secret".path;
           };
+          # Stage 3 (docs/plans/immich-keycloak-sso.md Part E): SSO is
+          # the only door for new logins, web and mobile alike. Break-
+          # glass: remove this line and redeploy (comin) to restore the
+          # password form; API keys keep authenticating regardless.
+          # The admin UI cannot flip this (system settings are frozen
+          # while the config file is in use) — the declaration is the
+          # truth. See the plan's Rollback section.
+          passwordLogin.enabled = false;
           notifications.smtp = {
```

Merge; comin switches srv-prod-4; the web password form disappears and
`/api/auth/login` stops accepting credentials. The `immich/smtp-*`
sops secrets stay (notifications); there is no local admin password
secret to keep — the break-glass is the env flip plus API keys (Part D
step 4 created the mobile path; scripts already hold API keys).

## Verification (final state)

```bash
# password sign-in is gone — the endpoint rejects with its stage-3 body:
curl -s -X POST https://photos.ritter.family/api/auth/login -H 'Content-Type: application/json' -d '{"email":"probe@example.com","password":"probe"}' -o - -w '\n%{http_code}\n'
# expected: '401' {"message":"Password login has been disabled"}
# (verified (2026-11-18) that today it answers {"message":"Incorrect email or password"})

# gatus stays green with SSO enabled (ping is public by design):
curl -s -o /dev/null -w '%{http_code}\n' https://photos.ritter.family/api/server/ping
# expected: '200'

# SSO end-to-end (client probe; same shape as every plan so far):
curl -s "https://account.ritter.family/realms/homelab/protocol/openid-connect/auth?client_id=immich&response_type=code&redirect_uri=https%3A%2F%2Fphotos.ritter.family%2Fauth%2Flogin&scope=openid&state=probe" -o /dev/null -w '%{http_code}\n'
# expected: '302'
```

The web login page renders client-side; the "password form gone, only
the Keycloak button" check is a UI check (upstream exposes no config
endpoint for it).

## Known effects

- **Auth dependency:** with Part E, new logins (web and mobile) require
  Keycloak (srv-prod-1) up. Break-glass: remove the
  `passwordLogin.enabled = false` line and redeploy — comin restores the
  password form. API keys keep working through any outage (they never
  touch the login endpoint), and already-issued sessions keep
  functioning while Keycloak is down.
- **Password-reset mails become moot for SSO users:** auto-registered
  users have no local password; the Brevo relay still sends them
  (invited-album mails etc. still make sense). The sops SMTP secrets
  stay.
- **Auto-create:** every realm user gets a seat — the realm's two
  admin-provisioned users are the allow-list. E-mail auto-linking is
  built in (Forgejo-like), unlike paperless's connect-flow; the
  bene-link depends on matching e-mails (Part D step 1).
- **Admin status stays Immich-side:** the realm delivers no
  `immich_role` claim; absent claims leave roles untouched and new
  users register non-admin. Nobody is promoted from a token.
- **Logout ends the realm session** (upstream default, opposite of
  Forgejo/PVE/Beszel/Paperless): OAuth sessions redirect through
  Keycloak's logout confirmation page with `id_token_hint`. Deliberate —
  a household member closing the shared-browser session closes all of
  it. Reversible later by setting `oauth.endSessionEndpoint` to a dummy
  or configuring backchannel logout instead (see follow-ups).
- **System settings are frozen while the config file is in use:** the
  admin UI rejects system-settings saves ("Cannot update configuration
  while IMMICH_CONFIG_FILE is in use"). Every OAuth/password-login
  change goes through the module; user management (accounts, e-mails,
  quotas, deletions) still works in the UI.
- **Public FQDN only:** logins opened at the aspect vhost
  (`photos.srv-prod-4.ritter.family`) send a redirect URI Keycloak
  rejects — the public FQDN is the one supported entry point (same
  caveat as every other service). Mobile apps must use
  `https://photos.ritter.family`.
- **Restart windows:** PR 2 and PR 3 bounce immich-server for a few
  seconds (normal comin activation; uploads retry client-side).
- **Rotation:** the client secret lives in two sops stores and the
  rendered config file; rotate with `sops set` on both (Part A
  command), `restartUnits` restarts immich-server on the re-render, and
  the pipeline apply mirrors the value into Keycloak.
- **SSO state and backups:** the OAuth links (`oauthId` on users) and
  sessions live in the immich PostgreSQL database like all other immich
  state. No repo-managed DB backup exists for srv-prod-4; Immich's
  built-in database backup (admin UI, dumps into the media location) is
  the current mechanism.

## Rollback

Per part, each restores the previous state on its own:

- **Part E:** remove the `passwordLogin.enabled = false` line, redeploy
  — the password form returns. Not self-pinning: the value lives in the
  rendered config file, which the module re-writes on every boot, so the
  declaration is the truth.
- **Part D:** disconnect the SSO identity (*Account settings →
  unlink OAuth*; verified `POST /api/oauth/unlink` in the controller).
  Not a deployment; nothing else to roll back.
- **Part C:** revert the module diff; comin switches back — the SSO
  button disappears, password login alone remains. The `oauth` block is
  re-rendered out of `/run/immich/config.json` on the next boot. Delete
  the sops entries if desired (`sops unset`; not idempotent, errors when
  the key is gone).
- **Part B:** set `enabled = false` in `client-immich.tf` and apply, or
  revert the PR — the pipeline apply **deletes the client**
  (state-based, like Forgejo). Part A's values can stay (unused secret,
  no harm).
- **Part A:** no undo needed; the end state is "values exist", and
  re-running overwrites them.

## Places that need no change (checked, with reasons)

- **`modules/hosts/srv-prod-4/configuration.nix` / `services/immich.nix`**
  — the SSO wiring lands inside the generic `immich` aspect (already a
  singleton that hardcodes its FQDN); no import-list change and no new
  `-on-<host>` instance. The NFS mount and unit mount-gate are
  auth-independent.
- **Edge proxy** (`modules/hosts/directions/services/https-proxy.nix`) —
  `photos.ritter.family` is already mapped to the aspect vhost with
  websockets, 50 GB bodies and 600 s timeouts; the OIDC callbacks are
  ordinary GETs/POSTs well inside those limits. No change.
- **DNS (`tofu/dns`, `tofu/network`)** — `*.ritter.family` wildcard on
  both the public and the LAN zone; no new record.
- **Homepage tile** (`modules/nixos/homepage.nix`) — URL and icon
  unchanged.
- **Gatus** (`modules/nixos/gatus.nix`) — check target `/api/server/ping`
  is public and `200` through every stage (**verified (2026-11-18)** for
  the current state; not an auth-gated route).
- **SMTP notifications** — independent of auth mode; the Brevo relay
  keeps working (see Known effects for what SSO changes semantically).
- **`docs/sso.md` / rollout table / `docs/homelab.md`** — updated at
  completion only (Cleanup), matching the Beszel/Nextcloud/Paperless
  flow.

## Cleanup / follow-ups

- [ ] Update the Immich row in
      [`keycloak-sso-rollout.md`](keycloak-sso-rollout.md) to ✅, add the
      Immich row to `docs/sso.md`'s "Services with SSO enabled" table,
      and archive this plan with `git mv` to
      `docs/plans/archive/YYYY-MM-DD-immich-keycloak-sso.md` per
      AGENTS.md. (While there: the Nextcloud and Paperless rows in the
      rollout table are stale — both onboardings completed in November;
      fix them in the same edit.)
- [ ] `docs/homelab.md`: add the Immich recital (config-file SSO wiring,
      sops keys, mobile OAuth story, password-flip break-glass,
      secret-rotation runbook).
- [ ] After a soak period: consider `oauth.autoLaunch = true`
      (straight-to-Keycloak login page; escape hatch
      `/auth/login?autoLaunch=0`).
- [ ] Optional: single logout hardening — set the Keycloak client's
      backchannel logout URL to
      `https://photos.ritter.family/api/oauth/backchannel-logout`
      (verified endpoint, RFC 8963 logout-token validation) so realm
      sessions ending elsewhere also kill Immich sessions.
- [ ] When `alina` first logs in: confirm her account self-created with
      a sane quota; adjust `oauth.defaultStorageQuota` if desired.
