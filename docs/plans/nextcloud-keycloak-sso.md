# Nextcloud: Keycloak SSO (next native client)

**Status:** planning (2026-11-13) — part of
[`keycloak-sso-rollout.md`](keycloak-sso-rollout.md) (step 2, the
Office/Media batch, "one client file at a time"). Client conventions
follow the Forgejo, PVE, Beszel and Paperless onboardings; app-side
staging follows Beszel's three-part pattern (SSO beside password login →
first SSO login → password login off). Claims marked
**verified (2026-11-13)** were checked against the live services, the
pinned nixpkgs and the user_oidc sources while writing this plan.

## Background

Nextcloud 35.0.2 runs on srv-prod-2 behind
`https://nextcloud.ritter.family` (**verified (2026-11-13)** via
`/status.php`). The generic aspect `modules/nixos/nextcloud/` is split
into unnamed parts that all set `flake.modules.nixos.nextcloud`
(`default.nix` for the service core, `richdocuments.nix` for the
Collabora wiring); the instance file
`modules/hosts/srv-prod-2/services/nextcloud.nix` adds the NFS data dir
and restic backups. The public FQDN is the aspect vhost's alias
(`trusted_domains` already carries it). PostgreSQL runs locally, and the
restic backup dumps the whole DB.

SSO facts (**verified (2026-11-13)** against the pinned nixpkgs
(rev `4fe25e12`) and the user_oidc sources, v8.11.0 unless noted):

- The pinned nixpkgs ships and **packages `user_oidc` 8.11.0** for
  Nextcloud 35 (`pkgs/servers/nextcloud/packages/35.json`), so the app
  joins `extraApps` declaratively — no app-store click-ops, no version
  drift on upgrades (the pin moves with the Nextcloud package).
- **PKCE is enabled by default** when the IdP's discovery endpoint
  advertises S256 support (`$isPkceEnabled = $isPkceSupported &&
  ($oidcSystemConfig['use_pkce'] ?? true)`, `LoginController.php:216`)
  — Keycloak advertises S256, so the realm-wide S256 enforcement holds
  without extra app config. `use_pkce` can be forced via `config.php`
  (`user_oidc.use_pkce = "force"`) if that default should ever change.
- **Auto-provisioning is on by default** and **soft** (default on): the
  login resolves the mapped user-ID claim and looks it up across all
  user backends (`userManager->get($userId)`, `LoginController.php:649`)
  — an **existing local account is reused** and its display name, e-mail
  and quota are updated from the token claims
  (`ProvisioningService.php`, `$existingLocalUser` path). Only unknown
  IDs create a fresh, unprivileged account. There is **no separate
  connect step** (unlike paperless) — linking is automatic, keyed on the
  user ID.
- Both knobs that would defeat that matching are non-defaults we set:
  the user-ID claim maps to **`sub` by default** (a Keycloak UUID) and
  `uniqueUid` defaults to **on** (IDs hashed with the provider id) —
  the plan sets `--mapping-uid preferred_username` and `--unique-uid 0`
  so realm `bene` lands in the existing local `bene` account.
- **Password login can be disabled** with
  `occ config:app:set user_oidc allow_multiple_user_backends
  --type=string --value=0`: with exactly one provider configured, the
  login page redirects straight to Keycloak. Admins keep a
  **regular-login door without any redeploy**:
  `https://nextcloud.ritter.family/login?direct=1` renders the password
  form (upstream guarantee).
- **Device clients keep working:** desktop and mobile apps
  authenticate through login flow v2 (browser + app password), and
  WebDAV/CalDAV/news clients use app passwords generated from the web
  session. App-password/token auth never routes through the login page,
  so hiding the form does not touch it — as long as the provider's
  `checkBearer` stays off (it defaults off; enabling it would require
  every API/DAV call to carry an OIDC token).
- **Single logout is on by default**: logging out of Nextcloud calls the
  provider's end_session_endpoint, ending the realm SSO session too —
  a deliberate difference from every service onboarded so far (there,
  logout only ended the app session).

What SSO does **not** touch:

- **Collabora (richdocuments)** — coolwsd and Nextcloud exchange WOPI
  tokens server-side; document open/edit never sees a browser redirect.
- **Background jobs and occ** — CLI work is session-free.
- **Gatus** (`modules/nixos/gatus.nix`) monitors
  `https://nextcloud.ritter.family/status.php` — **verified (2026-11-13)**:
  public by core design, answers `200` today, and no `user_oidc`
  code path gates it. The rollout plan's "exclude the health endpoint
  from SSO" question answers itself for this service: the check stays
  where it is.

## Chosen approach

The Keycloak side is tofu-managed like every client: one file per client
(`tofu/keycloak/client-nextcloud.tf`), confidential client,
authorization-code flow with PKCE S256 enforced (safe by default here —
user_oidc sends challenges unless the IdP lacks S256 support). The
client secret is operator-generated and seeded into both sops stores
(`tofu/keycloak/secrets.json` for the pipeline, srv-prod-2's
`secrets.yaml` for the app), so both sides match by construction — the
Forgejo/Paperless pattern.

**Where the wiring lives on the app side:** a new unnamed part
`modules/nixos/nextcloud/sso.nix` that merges into
`flake.modules.nixos.nextcloud` — the same decomposition
`richdocuments.nix` already uses, gated with
`lib.mkIf config.services.nextcloud.enable`. It adds the `user_oidc`
app to `extraApps`, declares the sops secret, and keeps the provider
config in sync with a systemd oneshot that runs occ
(`nextcloud-useroidc-config` — the same pattern as
`nextcloud-richdocuments-config`). The occ route is not optional
imperative config: user_oidc stores providers (secret included,
encrypted) in the Nextcloud database, so a web-UI setup would be
untracked click-ops; the oneshot makes the DB row a product of the
declaration instead. `--clientsecret-file` feeds the secret without it
appearing in argv or in the unit file.

**User mapping:** the realm's two users (`bene`, `alina`) map onto
Nextcloud by `preferred_username`. `bene` has an existing local account
(files, shares, quota) — soft auto-provisioning links realm `bene` onto
it on first SSO login. `alina` either links onto her existing account or
self-creates a fresh unprivileged one — the rollout plan's auto-create
end state, effective from day one, safe because the realm has
registration off and exactly two admin-provisioned users (the
allow-list reasoning from
`tofu/keycloak/README.md` → "Restricting who can use a client"). The
local admin account (created at install; the nixpkgs module passes
`--disable-admin-user` on installs and can no longer manage its
password) never touches SSO — its uid matches no realm user, and it
stays the break-glass credential behind `?direct=1` (see Part E).

**Password login is disabled in stage 3** via
`allow_multiple_user_backends=0` — same pros/cons as Beszel's Part C
(no second phishable credential; authentication then depends on Keycloak
on srv-prod-1 being up), but with the cheapest break-glass of all
services so far: `?direct=1` restores the password form with zero
redeploy, so a Keycloak outage does not strand the data.

Staging:

| Stage | What | Where |
| --- | --- | --- |
| 0 | Generate + seed secrets | operator command (Part A) |
| 1 | tofu client (S256 enforced) | PR 1 (pipeline applies) |
| 2 | Stage-1 code: user_oidc app + provider oneshot, SSO button beside password | PR 2 (comin switches srv-prod-2) |
| 3 | Click-ops: first SSO logins, app-password check, device-client check | Part D, operator (~10 min) |
| 4 | Part E: password login off | PR 3 |
| 5 | Completion | docs/homelab.md, sso.md + rollout table, archive |

Order constraint: **PR 1 must land before PR 2** — Keycloak would reject
every SSO attempt for a client that does not exist yet (the client probe
below answers `400`/`Client not found` today, **verified (2026-11-13)**).
While only PR 1 is applied, the app has no SSO button at all and nothing
user-visible changes.

## Part A — secret seeding (operator, before PR 1; not idempotent — `sops set` overwrites)

The tofu pipeline reads `nextcloud_client_secret` at plan time, so the
sops stores must hold the values before PR 1 can plan. Run from the repo
root on framework-13 (the age identity is not available in CI or
sandbox sessions — same caveat as the Beszel/Stirling/Paperless
seedings):

```bash
unset CLIENT_SECRET
# generate e.g. with: head -c 24 /dev/urandom | base64 | tr -d '/+='
read -rs -p "nextcloud client secret: " CLIENT_SECRET; echo
printf '%s' "$CLIENT_SECRET" | jq -R . | \
  sops set tofu/keycloak/secrets.json '["nextcloud_client_secret"]' --value-stdin
printf '%s' "$CLIENT_SECRET" | jq -R . | \
  sops set modules/hosts/srv-prod-2/secrets.yaml '["nextcloud"]["keycloak-client-secret"]' --value-stdin
unset CLIENT_SECRET
```

Nested path under the existing `nextcloud:` mapping (the dashed-key form
the Forgejo plan settled on). Equality check across the two stores (no
output, exit 0 = byte-identical; ciphertexts differ because each
encryption mints fresh IVs):

```bash
diff <(sops -d --extract '["nextcloud_client_secret"]' tofu/keycloak/secrets.json | sha256sum) \
     <(sops -d --extract '["nextcloud"]["keycloak-client-secret"]' modules/hosts/srv-prod-2/secrets.yaml | sha256sum)
```

## Part B — tofu client (PR 1)

Full content of the new file (one file per client, per the convention):

```diff
@@ tofu/keycloak/client-nextcloud.tf @@
+# One OIDC client per service, one file per client.
+resource "keycloak_openid_client" "nextcloud" {
+  realm_id  = keycloak_realm.homelab.id
+  client_id = "nextcloud"
+  name      = "Nextcloud"
+  enabled   = true
+
+  access_type                  = "CONFIDENTIAL"
+  standard_flow_enabled        = true
+  direct_access_grants_enabled = false
+  # user_oidc sends PKCE by default whenever the IdP advertises S256
+  # (Keycloak does — verified in the 8.11.0 source, LoginController.php),
+  # so S256 is enforced here like on every other client. Land this PR
+  # before the stage-1 module change (PR 2), or the deployed button
+  # would target a client that does not exist yet.
+  pkce_code_challenge_method = "S256"
+
+  # Operator-generated and seeded into both sops stores (tofu's
+  # secrets.json for the pipeline, srv-prod-2's yaml for the app's
+  # oneshot) so the two sides match by construction. Seeding command:
+  # docs/plans/nextcloud-keycloak-sso.md, Part A.
+  client_secret = data.sops_file.secrets.data["nextcloud_client_secret"]
+
+  # user_oidc builds the redirect_uri with
+  # linkToRouteAbsolute('user_oidc.login.code') (verified,
+  # LoginController.php) — whether Nextcloud renders the pretty form or
+  # the index.php form depends on the instance's URL-rewrite config,
+  # which the nixos module does not pin. Both variants are whitelisted
+  # so the client is correct either way; exactly one is exercised (the
+  # app's admin settings page displays the effective one), the other is
+  # inert. Logins opened at the aspect vhost
+  # (nextcloud.srv-prod-2.ritter.family) would send a different origin
+  # and fail Keycloak's redirect check — the public FQDN is the one
+  # supported entry point (same caveat as every other service).
+  valid_redirect_uris = [
+    "https://nextcloud.ritter.family/apps/user_oidc/code",
+    "https://nextcloud.ritter.family/index.php/apps/user_oidc/code",
+  ]
+}
```

The `OpenTofu Keycloak` pipeline plans on the PR and applies on merge.
Check after merge, from the public side:

```bash
curl -s "https://account.ritter.family/realms/homelab/protocol/openid-connect/auth?client_id=nextcloud&response_type=code&redirect_uri=https%3A%2F%2Fnextcloud.ritter.family%2Fapps%2Fuser_oidc%2Fcode&scope=openid&state=probe" -o /dev/null -w '%{http_code}\n'
# expected: '302' — Keycloak accepted client + redirect URI (same probe
# as the Beszel/Stirling/Paperless plans; the browser flow carries the
# extras). Verified (2026-11-13): answers '400' (Client not found)
# before the client exists, so the probe also proves the apply.
```

Stage gate: the probe must answer `302` before PR 2 lands.

## Part C — stage-1 code: SSO beside password (PR 2)

Full content of the new part file (the `richdocuments.nix` cut: another
unnamed part merging into the `nextcloud` aspect; `default.nix` and the
srv-prod-2 instance file stay untouched):

```diff
@@ modules/nixos/nextcloud/sso.nix @@
+{ config, lib, ... }:
+let
+  occ = lib.getExe config.services.nextcloud.occ;
+in
+lib.mkIf config.services.nextcloud.enable {
+  # user_oidc is packaged in nixpkgs for Nextcloud 35 (8.11.0, pinned in
+  # packages/35.json) — extraApps keeps it in lockstep with the Nextcloud
+  # package on upgrades, no app-store drift.
+  services.nextcloud.extraApps = {
+    inherit (config.services.nextcloud.package.packages.apps) user_oidc;
+  };
+
+  # Read by the oneshot below via occ's --clientsecret-file (the secret
+  # must not land in argv or the world-readable unit file). Rotation
+  # re-runs the oneshot, which re-encrypts the value into the database.
+  sops.secrets."nextcloud/keycloak-client-secret" = {
+    owner = "nextcloud";
+    restartUnits = [ "nextcloud-useroidc-config.service" ];
+  };
+
+  # Keycloak SSO (docs/plans/nextcloud-keycloak-sso.md): user_oidc
+  # stores providers (secret included, encrypted) in the Nextcloud
+  # database, so this oneshot keeps the DB row in sync with the
+  # declaration — same pattern as nextcloud-richdocuments-config.
+  # Idempotent: user_oidc:provider is an upsert by identifier; re-running
+  # also clears the provider's JWKS cache (harmless). --mapping-uid +
+  # --unique-uid 0 override the defaults (sub claim, provider-hashed
+  # IDs) so the user ID is the realm preferred_username and soft auto
+  # provisioning links onto the existing local accounts instead of
+  # creating hashed-ID duplicates.
+  systemd.services.nextcloud-useroidc-config = {
+    after = [ "nextcloud-setup.service" ];
+    requires = [ "nextcloud-setup.service" ];
+    wantedBy = [ "multi-user.target" ];
+    serviceConfig.Type = "oneshot";
+    script = ''
+      ${occ} user_oidc:provider keycloak \
+        --clientid nextcloud \
+        --clientsecret-file ${config.sops.secrets."nextcloud/keycloak-client-secret".path} \
+        --discoveryuri https://account.ritter.family/realms/homelab/.well-known/openid-configuration \
+        --mapping-uid preferred_username \
+        --unique-uid 0
+
+      # Stage 1: both doors open. Stage 3 (Part E) flips this to 0 —
+      # the login page then redirects to Keycloak and the password form
+      # is only reachable with /login?direct=1.
+      ${occ} config:app:set user_oidc allow_multiple_user_backends --type=string --value=1
+    '';
+  };
+}
```

Notes for review:

- `lib.mkIf config.services.nextcloud.enable` makes the part inert on
  any host that runs the aspect without the service (mirrors
  `richdocuments.nix`); nothing else in the repo imports `nextcloud`
  today besides srv-prod-2's instance.
- The scope stays the upstream default `openid email profile` — enough
  for the e-mail/display-name claims soft provisioning consumes.
- `checkBearer` keeps its default (off) deliberately: app passwords keep
  working as DAV credentials. No option is set for it — the absence is
  the decision.

```bash
nix flake check && nix fmt   # gate before opening the PR
```

Merge; comin switches srv-prod-2; the oneshot runs once at activation
and enables the app. Verify:

```bash
# the app is enabled and the provider registered (occ is idempotent to re-run)
ssh root@srv-prod-2.ritter.family 'nextcloud-occ user_oidc:provider keycloak'

# the login page now offers Keycloak beside the password form
curl -s https://nextcloud.ritter.family/login | grep -o '/apps/user_oidc/login/keycloak' | head -n1
# expected: '/apps/user_oidc/login/keycloak'

# gatus stays green throughout — status.php is public by design
curl -s -o /dev/null -w '%{http_code}\n' https://nextcloud.ritter.family/status.php
# expected: '200'
```

Stage gate: do not proceed to Part D before the button is in the login
page HTML and the oneshot has exited 0.

## Part D — click-ops: first SSO logins (operator, ~10 min; the stage gate)

Ordered so the password door stays open the whole time:

1. Sign out (or use a private window) and open
   `https://nextcloud.ritter.family`. The login page shows the Keycloak
   button beside the password form. Sign in via **Keycloak** as `bene`.
2. Confirm the session lands in the **existing** `bene` account: same
   files, shares and quota as before (soft auto-provisioning linked the
   realm identity onto it, keyed on `preferred_username`). Display name
   and e-mail are refreshed from the realm claims on each login.
3. Log out. Note this ends the realm session too (single logout, default
   on) — expected, see Known effects. Sign in via Keycloak once more.
4. **Device surfaces, before Part E hides the form:** generate an app
   password (*Settings → Security*) and confirm (a) a WebDAV mount and
   (b) a CalDAV/calendar client authenticate with
   `bene <app-password>`. The desktop client's existing session keeps
   working (it holds an app password, not the account password); if it
   ever re-logins, login flow v2 opens the browser and SSO just works.
5. `alina`'s first SSO login links onto her existing local account or
   self-creates a fresh, unprivileged one — the rollout plan's
   auto-create end state. No operator step unless a stray account
   appears.
6. Check *Administration → Users*: no account other than the known
   locals and their realm links should have appeared. A stray
   hashed-UID account would mean the `--mapping-uid`/`--unique-uid 0`
   settings did not take effect — fix the oneshot and delete the stray
   before proceeding.

Stage gate: do not proceed to Part E until step 2 and step 4 have
passed — with password login off, the web door must already be the
realm identity and DAV clients must already hold app passwords.

## Part E — password login off (PR 3)

```diff
@@ modules/nixos/nextcloud/sso.nix @@
       # Stage 1: both doors open. Stage 3 (Part E) flips this to 0 —
       # the login page then redirects to Keycloak and the password form
-      # is only reachable with /login?direct=1.
-      ${occ} config:app:set user_oidc allow_multiple_user_backends --type=string --value=1
+      # is only reachable with /login?direct=1. Break-glass without any
+      # redeploy: https://nextcloud.ritter.family/login?direct=1 shows
+      # the regular login form (upstream guarantee). See the plan's
+      # Rollback section.
+      ${occ} config:app:set user_oidc allow_multiple_user_backends --type=string --value=0
```

Merge; comin switches srv-prod-2; the oneshot re-runs on the switch (its
unit definition changed) and `/login` starts redirecting to Keycloak.
The `nextcloud/admin-pass` sops secret deliberately **stays** — it is
the break-glass credential (usable at `?direct=1`; if it no longer
matches, set a fresh password with `nextcloud-occ user:resetpassword
<admin-user>`).

## Verification (final state)

```bash
# /login redirects to Keycloak (302 — first hop of the auto-redirect);
# ?direct=1 still renders the password form (200) — the break-glass:
curl -s -o /dev/null -w '%{http_code}\n' https://nextcloud.ritter.family/login
# expected: '302'
curl -s -o /dev/null -w '%{http_code}\n' 'https://nextcloud.ritter.family/login?direct=1'
# expected: '200'

# gatus stays green with SSO enabled (status.php is public by design):
curl -s -o /dev/null -w '%{http_code}\n' https://nextcloud.ritter.family/status.php
# expected: '200'

# SSO end-to-end (client probe; same shape as every plan so far):
curl -s "https://account.ritter.family/realms/homelab/protocol/openid-connect/auth?client_id=nextcloud&response_type=code&redirect_uri=https%3A%2F%2Fnextcloud.ritter.family%2Fapps%2Fuser_oidc%2Fcode&scope=openid&state=probe" -o /dev/null -w '%{http_code}\n'
# expected: '302'
```

## Known effects

- **Auth dependency:** with Part E, logging into the web UI requires
  Keycloak (srv-prod-1) up. Break-glass: `?direct=1` on the login URL
  renders the password form **without any redeploy** — the cheapest
  recovery of all services onboarded so far — and the sops
  `nextcloud/admin-pass` (or `nextcloud-occ user:resetpassword`) is the
  working key. Flipping `allow_multiple_user_backends` back to `1` is
  the durable revert (Part E diff reversed).
- **DAV/API clients unaffected:** app passwords and login-flow-v2
  tokens never route through the login page (upstream guarantee);
  `allow_multiple_user_backends` only changes what the login page
  shows. The provider's `checkBearer` must stay **off** (default) —
  enabling it would move API/DAV auth onto OIDC bearer tokens and break
  every app-password client.
- **Auto-create:** every realm user gets a seat — the realm's two
  admin-provisioned users are the allow-list. Soft auto-provisioning
  updates display name, e-mail and quota from realm claims on every
  login; the realm values win.
- **Single logout:** signing out of Nextcloud ends the realm SSO
  session (end_session_endpoint, default on) — the opposite of every
  service onboarded so far. Deliberate: a household member closing the
  shared-browser session should close all of it.
- **Logout now redirects through Keycloak:** because single logout is
  on, the logout flow round-trips the realm. Harmless, but noticeably
  different from the other services' logout UX.
- **Aspect vhost is not an SSO entry point:** logins opened at
  `nextcloud.srv-prod-2.ritter.family` send a redirect URI Keycloak
  rejects — the public FQDN is the one supported entry point (same
  caveat as every other service).
- **Restart windows:** PR 2 bounces the Nextcloud services for a few
  seconds (normal comin activation); the oneshot runs once per
  activation, and a secret rotation re-runs it (occ upsert, seconds).
- **Rotation:** rotate with `sops set` on both stores (Part A command);
  `restartUnits` re-runs the oneshot, which re-encrypts the secret into
  the database, and the pipeline apply mirrors the value into Keycloak.
- **Upgrades:** the `user_oidc` pin moves with the nixpkgs Nextcloud
  package (35.json), so app and server compatibility is the nixpkgs
  maintainers' problem, not ours.

## Rollback

Per part, each restores the previous state on its own:

- **Part E:** flip `allow_multiple_user_backends` back to `--value=1`
  (revert the PR; comin switches back) — the password form returns for
  everyone. Faster: `?direct=1` reaches the form immediately without a
  deploy. Not self-pinning: the value lives in the DB but is re-set by
  the oneshot on every activation, so the declaration is the truth.
- **Part D:** nothing to roll back — linking created no second
  credential; realm identities can be reviewed (and stray accounts
  deleted) in *Administration → Users*.
- **Part C:** revert the module diff; comin switches back — new
  activations no longer touch the app. The switch alone does **not**
  disable it (the module only runs `app:enable` for `extraApps`
  entries, never `app:disable` — verified in the module source), so
  disable it explicitly:
  `nextcloud-occ app:disable user_oidc` (idempotent; errors when
  already disabled). That removes the SSO button; the password form
  remains. Fully remove the provider row with
  `nextcloud-occ user_oidc:provider:delete keycloak` (not idempotent —
  errors once gone) if desired.
- **Part B:** set `enabled = false` in `client-nextcloud.tf` and apply,
  or revert the PR — the pipeline apply **deletes the client**
  (state-based, like Forgejo). Part A's values can stay (unused secret,
  no harm).
- **Part A:** no undo needed; the end state is "values exist", and
  re-running overwrites them.

## Places that need no change (checked, with reasons)

- **`modules/nixos/nextcloud/default.nix`** — the SSO wiring lands in a
  new unnamed part (`sso.nix`) so the service core diff is zero; the
  module system merges parts that set the same registry key (the
  `richdocuments.nix` pattern).
- **`modules/hosts/srv-prod-2/services/nextcloud.nix`** — NFS mount,
  tmpfiles and restic backups are auth-independent. The provider row and
  the OIDC backend tables live in the Nextcloud PostgreSQL database,
  which the existing restic backup already dumps (`pg_dump` in
  `backupPrepareCommand`) — SSO state is backed up from day one.
- **Collabora / `richdocuments.nix`** — WOPI token flow between coolwsd
  and Nextcloud is server-side; no browser redirect, no SSO surface.
- **`modules/nixos/https-proxy`** — the vhost proxies all paths
  (including `/apps/user_oidc/*`) to the local nginx; no proxy change.
- **DNS (`tofu/dns`)** — `*.ritter.family` wildcard; no new record.
- **Homepage tile** (`modules/nixos/homepage.nix`) — URL and icon
  unchanged.
- **Gatus** — check target `/status.php` stays public and `200` through
  every stage (**verified (2026-11-13)** for the current state; no
  user_oidc code path gates it).
- **Desktop client module** (`modules/home/programs/nextcloud-client.nix`)
  — the package is unchanged; existing sessions hold app passwords and
  survive every stage.
- **`docs/sso.md` / rollout table / `docs/homelab.md`** — updated at
  completion only (Cleanup), matching the Beszel/Stirling/Paperless
  flow.

## Cleanup / follow-ups

- [ ] Update the Nextcloud row in
      [`keycloak-sso-rollout.md`](keycloak-sso-rollout.md) to ✅, add the
      Nextcloud row to `docs/sso.md`'s "Services with SSO enabled"
      table, and archive this plan with `git mv` to
      `docs/plans/archive/YYYY-MM-DD-nextcloud-keycloak-sso.md` per
      AGENTS.md.
- [ ] `docs/homelab.md`: add the Nextcloud recital (occ-oneshot
      provider config, sops keys, `?direct=1` break-glass, app-password
      story for DAV/desktop clients, secret-rotation runbook).
- [ ] After a soak period: revisit single logout — flip
      `user_oidc.single_logout = false` (system config) if the
      realm-wide logout side effect annoys.
- [ ] When `alina` first logs in: confirm her account linked (or
      self-created) with a sane default quota.
- [ ] Optional hardening, unprioritized: block `?direct=1` for non-LAN
      sources at the proxy if the break-glass ever moves to ssh +
      env-flip only.
