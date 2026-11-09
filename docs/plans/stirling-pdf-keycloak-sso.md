# Stirling PDF: Keycloak SSO (next native client)

**Status:** in progress — Part A ✅ (secrets seeded 2026-11-09), PR 1 +
later parts pending. Part of
[`keycloak-sso-rollout.md`](keycloak-sso-rollout.md) (step 2, the
Office/Media batch). Client conventions follow the Forgejo, PVE and
Beszel onboardings; app conventions follow Beszel's three-part staging
(SSO beside password login → first SSO login → password login off).

## Background

Stirling PDF (`pkgs.stirling-pdf-free`, v3.1.0 — verified via
`curl https://pdf.ritter.family/api/v1/info/status` →
`{"version":"3.1.0","status":"UP"}` on 2026-11-09) is a Spring Boot app
on srv-prod-2 behind `https://pdf.ritter.family`. To date **login has
never been enabled**: the analytics-free Free build serves the editor to
anyone who reaches it. That makes this onboarding the mirror image of
Beszel's — the pre-existing-user question is empty (there are no Stirling
accounts to map), but security is being *added* where none existed.

Dependencies to know about:

- **Native OIDC belongs to Stirling PDF's docs as a first-class Keycloak
  provider** (`security.oauth2.client.keycloak.*`, provider registration
  via issuer discovery). Env vars per the
  [OAuth2 / OIDC SSO docs](https://docs.stirlingpdf.com/Server/Security/OAuth-SSO/):
  - `SECURITY_ENABLELOGIN=true`, `SECURITY_OAUTH2_ENABLED=true`
  - `SECURITY_OAUTH2_CLIENT_KEYCLOAK_ISSUER=https://account.ritter.family/realms/homelab`
  - `SECURITY_OAUTH2_CLIENT_KEYCLOAK_CLIENTID=stirling-pdf`
  - `SECURITY_OAUTH2_CLIENT_KEYCLOAK_CLIENTSECRET=<sops>`
  - `SECURITY_OAUTH2_CLIENT_KEYCLOAK_SCOPES="openid, profile, email"`
  - `SECURITY_OAUTH2_CLIENT_KEYCLOAK_USEASUSERNAME=preferred_username`
  - `SECURITY_OAUTH2_AUTOCREATEUSER=true`, `SECURITY_OAUTH2_BLOCKREGISTRATION=false`
  - `SECURITY_LOGINMETHOD=all|oauth2` (Part C flips it to `oauth2`)
  - `SECURITY_INITIALLOGIN_USERNAME/PASSWORD` (first admin, break-glass)
- **Callback:** `https://pdf.ritter.family/login/oauth2/code/keycloak` —
  the registration id in the path is the provider block's name, not a
  setting, so the redirect URI is fixed.
- **Gatus** (`modules/nixos/gatus.nix`) monitors
  `https://pdf.ritter.family` for `200` — ambiguous once sign-in gates
  the UI. The answer to the rollout plan's "exclude the health endpoint
  from SSO" question for this service is upstream-guaranteed:
  `GET /api/v1/info/status` is public and unauthenticated even with login
  on ([Usage monitoring docs](https://docs.stirlingpdf.com/Server/Operations/Usage-Monitoring/),
  verified live pre-change). The check moves there in stage 1.
- **Realm is the outer shell:** with `blockRegistration: false` and
  `autoCreateUser: true` everyone in the realm gets a seat on first
  sign-in — deliberate and safe because the realm has registration off
  and one admin-set user (`tofu/keycloak/README.md` → "Restricting who
  can use a client").
- **Free-plan seats:** 5 users; the break-glass admin + the SSO account
  use two.

## Chosen approach

Tofu-managed confidential client
(`tofu/keycloak/client-stirling-pdf.tf`, one file per client),
authorization-code flow, secret operator-generated and seeded into both
sops stores (tofu's `secrets.json` and srv-prod-2's `secrets.yaml`) —
unlike Beszel there is no paste-into-UI step: Stirling's provider config
is plain env, so one seeding makes both sides match by construction.

No PKCE enforcement (`pkce_code_challenge_method` unset, unlike Forgejo
and Beszel): Stirling registers the provider through Spring Security's
issuer discovery and, being a confidential client, sends no PKCE
challenge. Keycloak merely doesn't require one — leaving the attribute
off is harmless whether or not the client sends the challenge.

**First boot with login on:** Stirling creates the initial admin only
from `SECURITY_INITIALLOGIN` when the user database is empty; the docs'
default (`admin`/`stirling`) is not acceptable as a public-facing
credential, so the break-glass admin password is seeded from sops
instead. Both settings are inert once users exist — keeping them in the
flake is self-documenting break-glass (Beszel kept
`DISABLE_PASSWORD_AUTH` the same way).

**User mapping:** none needed — login-off today means no accounts exist.
The first SSO login creates the user (`preferred_username` → `bene`);
the seeded admin then promotes it to Admin in Settings → Workspace →
Users. That promotion is the stage gate for Part C.

**Password login disabled in stage 3** via
`SECURITY_LOGINMETHOD = "oauth2"` — same pros/cons as Beszel's Part C
(no second phishable credential, reversible by removing one env line;
authentication now rides on Keycloak on srv-prod-1). Stirling-specific
extra: with `loginMethod: oauth2` the seeded password admin cannot sign
in either — the break-glass is flipping the env line back, not the
password itself, so the sops secret stays.

Staging:

| Stage | What | Where |
| --- | --- | --- |
| 0 | Generate + seed secrets | operator command (Part A) — ✅ 2026-11-09 |
| 1 | tofu client | PR 1 (tofu pipeline applies) |
| 2 | Stage-1 env: sign-in on, SSO beside password; gatus re-point | PR 2 (comin switches srv-prod-2) |
| 3 | Click-ops: first SSO login, promote to Admin | Part D, operator (~3 min) |
| 4 | Part E: password login off | PR 3 |
| 5 | Completion | docs/homelab.md, rollout table, archive |

## Part A — secret seeding (operator, before PR 1) ✅ (2026-11-09)

The tofu pipeline reads `stirling_pdf_client_secret` at plan time, so the
sops stores must hold the values before PR 1 can plan. Run from the repo
root on framework-13 (the age identity is not available in CI or sandbox
sessions — same caveat as the Beszel seeding):

```bash
unset CLIENT_SECRET ADMIN_PASSWORD
# 8+ chars; generate e.g.: head -c 24 /dev/urandom | base64 | tr -d '/+='
read -rs -p "stirling-pdf client secret: " CLIENT_SECRET; echo
read -rs -p "stirling-pdf initial admin password: " ADMIN_PASSWORD; echo
printf '%s' "$CLIENT_SECRET" | jq -R . | \
  sops set tofu/keycloak/secrets.json '["stirling_pdf_client_secret"]' --value-stdin
printf '%s' "$CLIENT_SECRET" | jq -R . | \
  sops set modules/hosts/srv-prod-2/secrets.yaml '["stirling-pdf"]["client-secret"]' --value-stdin
printf '%s' "$ADMIN_PASSWORD" | jq -R . | \
  sops set modules/hosts/srv-prod-2/secrets.yaml '["stirling-pdf"]["admin-password"]' --value-stdin
unset CLIENT_SECRET ADMIN_PASSWORD
```

`sops set` creating *nested* YAML keys turned out to work exactly as
written (proven on 2026-11-09 — the fallback to `sops edit` above was
never needed; the flat-JSON caveat came from the Beszel seed). The
values stay out of the repo and this transcript; keep them out of the
shell history too (`read -s` covers the transcript, `unset` covers the
variable table).

Equality check across the two stores (no output, exit 0 = the client
secret is byte-identical on both sides — the ciphertexts themselves
differ because each encryption mints fresh IVs):

```bash
diff <(sops -d --extract '["stirling_pdf_client_secret"]' tofu/keycloak/secrets.json | sha256sum) \
     <(sops -d --extract '["stirling-pdf"]["client-secret"]' modules/hosts/srv-prod-2/secrets.yaml | sha256sum)
```

## Part B — tofu client (PR 1)

Full diff of the new file (this is `tofu/keycloak/client-stirling-pdf.tf`
as it lands in the PR — identical to the file created alongside this
plan):

```diff
@@ tofu/keycloak/client-stirling-pdf.tf @@
+# One OIDC client per service, one file per client.
+resource "keycloak_openid_client" "stirling_pdf" {
+  realm_id  = keycloak_realm.homelab.id
+  client_id = "stirling-pdf"
+  name      = "Stirling PDF"
+  enabled   = true
+
+  access_type                  = "CONFIDENTIAL"
+  standard_flow_enabled        = true
+  direct_access_grants_enabled = false
+  # Deliberately no pkce_code_challenge_method: Stirling-PDF registers the
+  # provider via Spring Security's ClientRegistrations.fromIssuerLocation
+  # and (being a confidential client with a secret) does not send a PKCE
+  # challenge — Forgejo and Beszel enforce PKCE because their code bases
+  # send it, Stirling does not. Keycloak merely does not require the
+  # challenge then, so leaving it off is safe in both directions; if a
+  # future Stirling version starts sending S256, setting the attribute is
+  # the follow-up, not a fix.
+  #
+  # Operator-generated and seeded into both sops stores (tofu's
+  # secrets.json for the pipeline, srv-prod-2's yaml for the app's env
+  # template) so the two sides match by construction. See the Stirling PDF
+  # plan's Part A for the seeding command:
+  # docs/plans/stirling-pdf-keycloak-sso.md
+  client_secret = data.sops_file.secrets.data["stirling_pdf_client_secret"]
+
+  # Stirling-PDF derives the callback from the request origin plus the
+  # fixed registration id of the provider block (/login/oauth2/code/keycloak).
+  # Logins opened at the aspect vhost (pdf.srv-prod-2.ritter.family) would
+  # send a different origin and fail Keycloak's redirect check — the
+  # public FQDN is the one supported entry point (same caveat as PVE and
+  # Beszel).
+  valid_redirect_uris = [
+    "https://pdf.ritter.family/login/oauth2/code/keycloak",
+  ]
+}
```

The `OpenTofu Keycloak` pipeline plans on the PR and applies on merge.
Check after merge, from the public side:

```bash
curl -s "https://account.ritter.family/realms/homelab/protocol/openid-connect/auth?client_id=stirling-pdf&response_type=code&redirect_uri=https%3A%2F%2Fpdf.ritter.family%2Flogin%2Foauth2%2Fcode%2Fkeycloak&scope=openid&state=probe" -o /dev/null -w '%{http_code}\n'
# expected: '302' — Keycloak accepted client + redirect URI (same probe
# as the Beszel plan; browser flow carries the extras)
```

Before the client exists the probe answers `400`(client not found), so
this also proves the apply. Stage gate: the probe must answer `302`
before PR 2 lands, otherwise the login page shows a dead SSO button for
one comin cycle.

## Part C — stage-1 code: sign-in on, SSO beside password (PR 2)

The SSO wiring goes into the **service aspect itself** — the same cut the
two earlier native-OIDC onboardings chose: forgejo carries its
`oauth2_client` settings, its Keycloak sops secret and the OIDC-source
registration in `modules/nixos/forgejo.nix` (the host file
`forgejo-on-srv-prod-6` only adds restic backups), and beszel-hub carries
`DISABLE_PASSWORD_AUTH` and its sops template in
`modules/nixos/beszel-hub.nix` (no host instance at all). Both are
singletons in practice, hardcoding their public FQDN — `stirling-pdf`
already did the same (`pdf.ritter.family` alias), so the OAuth env and
sops wiring belong in `modules/nixos/stirling-pdf.nix`, and srv-prod-2's
import list in `configuration.nix` stays untouched.

Full diff of the module change (`modules/nixos/stirling-pdf.nix`;
tessdata, calibre and proxy blocks are unchanged — the `<ENC[...]>` s
placeholders are not copyable, the template reads
`config.sops.placeholder."…"` at build time):

```diff
@@ modules/nixos/stirling-pdf.nix @@
 _: {
   flake.modules.nixos.stirling-pdf =
     { config, pkgs, ... }:
     let
       deu-traineddata = pkgs.fetchurl {
         url = "https://github.com/tesseract-ocr/tessdata/raw/refs/heads/main/deu.traineddata";
         hash = "sha256-iWs7SVZQOrnaoQKF2zMIgbLXS3DYibeSYsxTS57GmaQ=";
       };
     in
     {
+      # Keycloak SSO (docs/plans/stirling-pdf-keycloak-sso.md): the
+      # client secret and the initial break-glass admin password come
+      # from sops; everything else is plain app configuration.
+      sops.secrets."stirling-pdf/client-secret" = { };
+      sops.secrets."stirling-pdf/admin-password" = { };
+      sops.templates."stirling-pdf/sso.env" = {
+        content = ''
+          SECURITY_OAUTH2_CLIENT_KEYCLOAK_CLIENTSECRET=<ENC[...] placeholder — not copyable>
+          SECURITY_INITIALLOGIN_PASSWORD=<ENC[...] placeholder — not copyable>
+        '';
+      };
+
       services.stirling-pdf = {
         enable = true;
         package = pkgs.stirling-pdf-free;
         environment = {
           INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "true";
           SYSTEM_ENABLEANALYTICS = "false";
           SERVER_PORT = 8090;
+
+          # Stage 1: SSO beside password login; Part E flips
+          # SECURITY_LOGINMETHOD to "oauth2".
+          SECURITY_ENABLELOGIN = true;
+          SECURITY_OAUTH2_ENABLED = true;
+          SECURITY_OAUTH2_CLIENT_KEYCLOAK_ISSUER = "https://account.ritter.family/realms/homelab";
+          SECURITY_OAUTH2_CLIENT_KEYCLOAK_CLIENTID = "stirling-pdf";
+          SECURITY_OAUTH2_CLIENT_KEYCLOAK_SCOPES = "openid, profile, email";
+          SECURITY_OAUTH2_CLIENT_KEYCLOAK_USEASUSERNAME = "preferred_username";
+          SECURITY_OAUTH2_AUTOCREATEUSER = true;
+          SECURITY_OAUTH2_BLOCKREGISTRATION = false;
+          SECURITY_INITIALLOGIN_USERNAME = "admin";
         };
+        environmentFiles = [ config.sops.templates."stirling-pdf/sso.env".path ];
       };
```

(The applied file additionally documents the choice of
`useAsUsername`, the realm-outer-shell reasoning behind
`autoCreateUser`/`blockRegistration`, and the role of the initial admin
— the diff drops those comments for brevity only. srv-prod-2 imports the
aspect unchanged, so `configuration.nix` needs no diff.)

And the gatus check moves onto the public health endpoint (same deploy
— srv-prod-2's comin switch brings both live together, so no window
where login gating and a `200`-only check disagree):

```diff
@@ modules/nixos/gatus.nix @@
             {
               name = "Stirling PDF";
-              url = "https://pdf.ritter.family";
+              # /api/v1/info/status is public and unauthenticated even
+              # with login on, so monitoring survives the Keycloak SSO
+              # rollout — see docs/plans/stirling-pdf-keycloak-sso.md.
+              url = "https://pdf.ritter.family/api/v1/info/status";
               interval = "5m";
               conditions = [
                 "[STATUS] == 200"
+                "[BODY].status == \"UP\""
               ];
             }
```

### Places that need no change (checked, with reasons)

- **`modules/hosts/srv-prod-2/configuration.nix`** — srv-prod-2 imports
  the `stirling-pdf` aspect directly; since the SSO wiring lands inside
  that same aspect (forgejo/beszel-hub cut), no import list change and
  no new `-on-<host>` instance.
- **`modules/nixos/https-proxy`** — the vhost already proxies with
  `recommendedProxySettings`, which sets `X-Forwarded-Proto/Host`
  (checked in the NixOS nginx module source). Stirling builds the
  callback from the forwarded headers, same as Forgejo does today.
- **Homepage tile** (`modules/nixos/homepage.nix`) — URL and icon
  unchanged.
- **Restic (`_restic-constants.nix` + per-service backup blocks)** —
  Stirling's state directory holds no user data today; with accounts it
  still only holds the (recreatable) user table. Noted as follow-up.
- **`docs/homelab.md`** — has no Stirling section yet; the from-scratch
  recital is added at completion (step 5 of the rollout plan).

### Verify (after comin switches srv-prod-2)

```bash
# health endpoint: monitoring target works and is unaffected by login
curl -s https://pdf.ritter.family/api/v1/info/status
# expected: {"version":"3.1.0","status":"UP"} (status field now checked by gatus)

# login is now required: the editor greets with the login page
curl -s https://pdf.ritter.family/ | grep -c 'sign-in\|Sign in' # non-zero in the SPA shell — UI check below is authoritative
```

Then in a browser: `https://pdf.ritter.family` → login page shows
**Sign in with Keycloak** (besides username/password), and gatus shows
"Stirling PDF" green on the new endpoint.

Stage gate: do not proceed to Part D until the first SSO login works
(Part D click-ops). Until then both doors work and nothing is locked
out.

## Part D — click-ops: first SSO login + Admin role (operator, ~3 min)

Ordered so password login stays available as the guardrail the whole
time:

1. Confirm stage-1 rolled out (gatus green, login page shows Keycloak).
2. `ssh root@srv-prod-2.ritter.family journalctl -u stirling-pdf -n 200`
   → confirm the app did **not** log "created default admin" but booted
   with the env-seeded initialLogin (the seeded password is in effect).
3. Private browser window → `https://pdf.ritter.family` → **Sign in
   with Keycloak** → realm flow → Stirling opens as a signed-in user
   (account `bene`, auto-created, role *user*).
4. Sign in with **admin** + the seeded `stirling-pdf/admin-password`
   (from `sops -d --extract '["stirling-pdf"]["admin-password"]'
   modules/hosts/srv-prod-2/secrets.yaml`) → Settings → Workspace →
   Users → role of the SSO user → **Admin**.
5. Log the admin out; verify in the SSO session that Settings are now
   reachable as `bene`.

Stage gate: do not proceed to Part E until 5 has passed — with password
login off, the sole admin path must already be the realm identity.

## Part E — password login off (PR 3)

```diff
@@ modules/nixos/stirling-pdf.nix @@
            SECURITY_ENABLELOGIN = true;
+          # SSO is the only door; break-glass is removing this line and
+          # signing in with the sops admin password. See
+          # docs/plans/stirling-pdf-keycloak-sso.md.
+          SECURITY_LOGINMETHOD = "oauth2";
            SECURITY_OAUTH2_ENABLED = true;
```

Merge; comin switches srv-prod-2; the password option disappears from
`/login` while Keycloak SSO keeps working. The seeded
`stirling-pdf/admin-password` deliberately **stays** in sops — it is the
break-glass credential for the env-flip.

Optional and deferred (evaluate separately, unverified env binding):
`SECURITY_SSOAUTOLOGIN=true` (settings.yml `security.ssoAutoLogin`)
would send users straight to the realm login; the docs note it only
applies with exactly one SSO provider configured, which holds here.

## Verification (final state)

```bash
# password sign-in is gone; /login shows only the Keycloak button (UI check)

# gatus stays green with SSO enabled:
curl -s https://pdf.ritter.family/api/v1/info/status
# expected: {"version":"…","status":"UP"}

# SSO end-to-end (client probe; the Beszel plan used the same shape):
curl -s "https://account.ritter.family/realms/homelab/protocol/openid-connect/auth?client_id=stirling-pdf&response_type=code&redirect_uri=https%3A%2F%2Fpdf.ritter.family%2Flogin%2Foauth2%2Fcode%2Fkeycloak&scope=openid&state=probe" -o /dev/null -w '%{http_code}\n'
# expected: '302'
```

## Known effects

- **UI lock-in:** after stage 1 the editor requires sign-in — household
  members need the realm account (the one `bene` user) for a previously
  open app. Gatus re-points in the same deploy, so monitoring never
  gaps.
- **Seats:** Free plan allows 5 users; 2 are used after Part D.
- **Auth dependency:** with Part E, logging into Stirling requires
  Keycloak (srv-prod-1) up. Break-glass = flip `SECURITY_LOGINMETHOD`
  back (env line), redeploy, sign in with the sops admin password.

## Rollback

Per stage, each restores the previous state on its own:

- Part E: remove the `SECURITY_LOGINMETHOD` line, redeploy — password
  sign-in returns (the admin account still exists).
- Part D is not a deployment: nothing to roll back.
- Part C: revert the env additions + sops template in
  `modules/nixos/stirling-pdf.nix` and the gatus diff — that is the full
  revert. Users created meanwhile stay in Stirling's state directory
  (harmless leftovers).
- Part B: `enabled = false` in `client-stirling-pdf.tf` + pipeline
  apply, or terraform-plan-style removal of the client. The sops
  entries stay (unused secret, no harm) or are removed with `sops
  delete`.
- Part A is idempotent (re-running overwrites the same keys); the
  stage-0 end-state is "secrets exist", so there is no step to undo.

## Cleanup / follow-ups

- [ ] Update the Stirling row in
      [`keycloak-sso-rollout.md`](keycloak-sso-rollout.md) to ✅ and
      archive this plan with `git mv docs/plans/… docs/plans/archive/…`
      per AGENTS.md (then link it as Beszel's is linked).
- [ ] `docs/homelab.md`: add the Stirling recital (env-only SSO wiring,
      sops keys, break-glass runbook, refresh steps for the two sops
      values).
- [ ] Consider a restic backup for `/var/lib/stirling-pdf` (login state,
      user table, and the settings persisted via the UI — email config,
      customizations would land there too).
- [ ] Optional: `SECURITY_SSOAUTOLOGIN=true` after a soak period.
- [ ] Next native office client per the rollout plan: Nextcloud, then
      Paperless, Immich, Vaultwarden.
