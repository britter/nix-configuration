# Forgejo on srv-prod-6: first Keycloak client (staged rollout)

**Status:** active. Part A (SMTP mailer) is **merged and verified**:
comin switched srv-prod-6, and the admin UI (Site Administration →
Configuration → Mailer Configuration) shows the SMTP settings; the
built-in "Send test email" form delivered a test mail successfully
(2026-10-29). A.4 (the e-mail click-ops on `britter`) is in progress —
that is the gate for Part B. Part B (the SSO client) is drafted and
gated behind A.4. The Keycloak deployment this builds on is complete and
archived at
[`docs/plans/archive/2026-10-29-keycloak-sso-on-srv-prod-1.md`](archive/2026-10-29-keycloak-sso-on-srv-prod-1.md)
(realm `homelab`, issuer `https://account.ritter.family/realms/homelab`,
`bene` user with e-mail set and verified in Keycloak, realm SMTP
working).

Status marks: ✅ done, ⏳ pending. Part A's rollout ends with the
account e-mail activated; Part B ends with the first SSO login landing
in `britter`.

## Chosen approach

Forgejo on srv-prod-6 (`git.ritter.family`) becomes the first OIDC
client of the `homelab` realm. Both halves are declarative: the Keycloak
side is tofu-managed (`keycloak/keycloak` provider in the
`tofu/keycloak` root, applied by the `OpenTofu Keycloak` pipeline on
merge), and Forgejo's side is an OAuth2 authentication source declared
in the forgejo module and created idempotently by
`forgejo admin auth add-oauth` in the service's `preStart` (it survives
rebuilds because it is state in Forgejo's database, not a Nix render).

Existing Forgejo accounts are linked to IdP identities **by e-mail**:
`ACCOUNT_LINKING = "auto"` signs a user in when the IdP-verified e-mail
matches an existing local account, without asking for the local
password. `ENABLE_AUTO_REGISTRATION = true` auto-creates accounts for
IdP users that match nothing — safe here because the realm has
registration off, so every realm account is admin-provisioned with a
unique admin-set e-mail.

Alternatives: creating Forgejo's auth source by hand in the web UI was
rejected because it stores state in Forgejo's database that no module
can reproduce; `ACCOUNT_LINKING = "login"` (ask the local password once)
was rejected because passwordless sign-in is the point of this rollout;
`client_secret_regenerate_when_changed` on the tofu side was rejected
because a pipeline-generated secret would then exist only in tofu state,
leaving Forgejo's copy without a git source of truth.

## Why the rollout is staged (the gate)

The original plan shipped mailer, `oauth2_client` settings, and the auth
source in one PR. That is unsafe, for two reasons that only matter
**before** the e-mail is fixed:

1. Changing Forgejo's account e-mail requires working outgoing mail:
   `britter`'s address is `root@localhost` and changing it requires an
   activation mail that must actually arrive.
2. Once `oauth2_client` settings are live, an SSO attempt whose IdP
   e-mail matches no Forgejo account **auto-registers a brand-new
   non-admin account** (username `bene`, from the `preferred_username`
   claim) instead of linking into the existing `britter` admin account.

So: **Part A** deploys only the mailer; the e-mail click-ops happen
while Forgejo's login behavior is untouched; **Part B** ships the SSO
client only at 4-after that gate, when `britter`'s address is confirmed
and identical to `bene`'s. This gate discipline is the reason
`britter` can't be locked out by a bad order of operations.

## Part A — SMTP mailer

### A.1 Secrets — done, stored ✅ (idempotent: no — `sops set` overwrites; re-running replaces values)

Brevo dashboard, one-time: Settings → *SMTP & API* → create a new SMTP
**key** for Forgejo (one key per service, as with vaultwarden and the
Keycloak realm); the login shown on that page is the username, the key
the password. Settings → *Senders* → add & validate `git@ritter.family`
(each service gets its own sender; `account@ritter.family` was reused by
the Keycloak realm).

sops writes, on framework-13, from the repo root. sops re-encrypts the
whole file, so a `sops set` needs the age identities of every repo rule
for the file; values move through pipes, never the clipboard.

**Path structure correction (learned 2026-10-29):** srv-prod-6's
`secrets.yaml` nests the forgejo keys under a top-level `forgejo:`
mapping, so sops key paths are `["forgejo"]["…"]` — a flat-path variant
(`["forgejo/keycloak-client-secret"]`) silently *creates a wrong
top-level key* instead of failing (the same pitfall the Keycloak plan
documents in its section 1.1: values arrive quoted (`jq -R .`), and a
misspelled key path is a silent no-op).

```bash
read -rs -p "Brevo SMTP login (for Forgejo): " SMTP_USER; echo
read -rs -p "Brevo SMTP key (for Forgejo): " SMTP_KEY; echo
printf '%s' "$SMTP_USER" | jq -R . | \
  sops set modules/hosts/srv-prod-6/secrets.yaml \
    '["forgejo"]["smtp-username"]' --value-stdin
printf '%s' "$SMTP_KEY" | jq -R . | \
  sops set modules/hosts/srv-prod-6/secrets.yaml \
    '["forgejo"]["smtp-password"]' --value-stdin
unset SMTP_USER SMTP_KEY
```

Executed 2026-10-29 (first attempt used underscore keys
`smtp_username`/`smtp_password`; corrected by copying the values into
the dashed keys and unsetting the wrong ones). Verified by reading the
encrypted file's plaintext key names — sops keeps keys visible, values
encrypted:

```
$ grep -nE '^ *[a-z0-9-]+:' modules/hosts/srv-prod-6/secrets.yaml
...
forgejo:
    admin-user-password: ENC[...]
    smtp-password: ENC[...]
    smtp-username: ENC[...]
```

(The `keycloak-client-secret` key is added in B.1, not here.)

### A.2 Repo changes

@@ modules/nixos/forgejo.nix @@

The sops declarations move to the **top** of the module and gain the
restart wiring; the pre-existing
`sops.secrets."forgejo/admin-user-password".owner = "forgejo";` line is
replaced by the attrset form:

```diff
+      # All forgejo secrets: owned by the forgejo user, and a rotation
+      # restarts the unit — credentials are bound at unit start (the
+      # preStart reads the admin password, LoadCredential injects the
+      # mailer credentials once), so a rotated secret must not leave a
+      # stale process reading old values.
+      sops.secrets."forgejo/admin-user-password" = {
+        owner = "forgejo";
+        restartUnits = [ "forgejo.service" ];
+      };
+      sops.secrets."forgejo/smtp-username" = {
+        owner = "forgejo";
+        restartUnits = [ "forgejo.service" ];
+      };
+      sops.secrets."forgejo/smtp-password" = {
+        owner = "forgejo";
+        restartUnits = [ "forgejo.service" ];
+      };
       services.forgejo = {
```

The mailer itself — verb settings plus the credentials wrapper inside
`services.forgejo`:

```diff
       services.forgejo = {
         enable = true;
         database.type = "sqlite3";
         settings = {
+          # Mailer: account e-mail changes need verification mails (A.4).
+          # Brevo relay, one SMTP key per service as with vaultwarden.
+          mailer = {
+            ENABLED = true;
+            PROTOCOL = "smtp+starttls";
+            SMTP_ADDR = "smtp-relay.brevo.com";
+            SMTP_PORT = 587;
+            FROM = "git@ritter.family";
+          };
           ...
         };
+        # SMTP credentials are injected as runtime credentials via the
+        # nixpkgs module's services.forgejo.secrets wrapper (LoadCredential
+        # + environment-to-ini; overrides settings), so they never appear
+        # in the generated app.ini.
+        secrets.mailer = {
+          USER = config.sops.secrets."forgejo/smtp-username".path;
+          PASSWD = config.sops.secrets."forgejo/smtp-password".path;
+        };
       };
```

Part A touches no tofu files, so the `OpenTofu Keycloak` pipeline does
not run for this PR.

### A.3 Verify, merge, switch

```bash
nix flake check && nix fmt   # ✅ passed locally (2026-10-29, all checks)
```

Merge; comin switches srv-prod-6 and Forgejo restarts with the mailer
wired. **Login behavior is unchanged at this point** — the switch is a
plain service config change. Do not touch SSO settings yet; the gate for
Part B is only complete at A.5.

If an earlier exploration had run the flat-path `sops set` variant
(creating a top-level key literally named
`forgejo/keycloak-client-secret`), remove the stray key; otherwise skip:

```bash
# idempotent: unset fails harmlessly when the key does not exist
sops unset modules/hosts/srv-prod-6/secrets.yaml \
  '["forgejo/keycloak-client-secret"]' 2>/dev/null || true
```

### A.4 Click-ops: change and activate britter's e-mail (the gate)

Signed into Forgejo as `britter` at `https://git.ritter.family`:

1. Settings → Profile → set the account e-mail to **the same address the
   Keycloak `bene` user carries** (`beneritter@gmail.com`; stated in the
   tofu root's `keycloak_user` resource).
2. Complete the verification mail sent from `git@ritter.family` and make
   it the primary address.

This exercise is simultaneously the mailer's end-to-end test. If the
mail never arrives: check `ssh root@srv-prod-6.ritter.family journalctl
-u forgejo` for mailer errors, then the Brevo key and the
`git@ritter.family` sender validation. Do not start Part B before the
mail path demonstrably works and the address is activated.

### A.5 Rollback (Part A)

`git revert`; comin switches back and the mailer disappears. Login is
unaffected either way — Forgejo still opens with password auth. The
verified e-mail stays active in Forgejo. Brevo's key and sender records
are inert and can stay.

## Part B — the SSO client

### B.1 Secrets (idempotent: no — run once, before opening Part B; ⏳ pending)

One generated client secret, stored twice: tofu reads it from
`tofu/keycloak/secrets.json` (the CI pipeline decrypts it — framework-13
and the GitHub runners hold the age keys), Forgejo from srv-prod-6's
`secrets.yaml`. Like A.1, nested paths for the yaml.

```bash
SECRET=$(openssl rand -base64 24 | tr -d '/+=')
printf '%s' "$SECRET" | jq -R . | \
  sops set tofu/keycloak/secrets.json '["forgejo_client_secret"]' --value-stdin
printf '%s' "$SECRET" | jq -R . | \
  sops set modules/hosts/srv-prod-6/secrets.yaml \
    '["forgejo"]["keycloak-client-secret"]' --value-stdin
unset SECRET
```

Values must match exactly on both sides (Forgejo's auth source keeps its
own copy in its database; a mismatch means the token endpoint rejects
the exchange with `invalid_client`).

### B.2 Repo changes

@@ tofu/keycloak/main.tf @@ (append)

```hcl
resource "keycloak_openid_client" "forgejo" {
  realm_id  = keycloak_realm.homelab.id
  client_id = "forgejo"
  name      = "Forgejo"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  # Forgejo sends PKCE (S256) on the authorization-code flow.
  pkce_code_challenge_method = "S256"

  # Operator-generated and seeded into both sops stores (tofu's
  # secrets.json for the pipeline, srv-prod-6's yaml for Forgejo's
  # preStart) so the two sides match by construction. Setting it
  # explicitly means every apply re-sends exactly this value (
  # UpdateOpenidClient embeds `secret` in the payload); refresh pulls
  # whatever Keycloak currently holds into state either way. See the
  # Known effects section for the rotation runbook.
  client_secret = data.sops_file.secrets.data["forgejo_client_secret"]

  # Forgejo's callback path embeds the auth source's NAME (B.2/B.3).
  valid_redirect_uris = [
    "https://git.ritter.family/user/oauth2/Keycloak/callback"
  ]
}
```

@@ modules/nixos/forgejo.nix @@

```diff
       sops.secrets."forgejo/smtp-password" = {
         owner = "forgejo";
         restartUnits = [ "forgejo.service" ];
       };
+      sops.secrets."forgejo/keycloak-client-secret" = {
+        owner = "forgejo";
+        restartUnits = [ "forgejo.service" ];
+      };

       services.forgejo = {
         ...
         settings = {
+          # Keycloak SSO (Part B): link IdP identities onto existing
+          # accounts by e-mail; auto-create accounts for users that exist
+          # in the IdP. Safe because the realm has registration off —
+          # every account is admin-provisioned, with unique admin-set
+          # e-mails — and because the account e-mails were activated
+          # first (A.4).
+          "oauth2_client" = {
+            ENABLE_AUTO_REGISTRATION = true;
+            ACCOUNT_LINKING = "auto";
+            USERNAME = "preferred_username";
+          };
           mailer = {
             ...
           };
           ...
         };
       };

       systemd.services.forgejo.preStart =
         let
-          adminCmd = "${lib.getExe config.services.forgejo.package} admin user";
+          forgejoCmd = "${lib.getExe config.services.forgejo.package}";
+          adminCmd = "${forgejoCmd} admin user";
           pwd = config.sops.secrets."forgejo/admin-user-password";
+          keycloakSecret = config.sops.secrets."forgejo/keycloak-client-secret";
           user = "britter"; # Note, Forgejo doesn't allow creation of an account named "admin"
         in
         ''
           ${adminCmd} create --admin --email "root@localhost" --username ${user} --password "$(tr -d '\n' < ${pwd.path})" || true
           ## uncomment this line to change an admin user which was already created
           # ${adminCmd} change-password --username ${user} --password "$(tr -d '\n' < ${pwd.path})" || true
+
+          # Keycloak OAuth2 source. Idempotent creation — grep-guard, the
+          # source is created once and never rewritten (a rotated client
+          # secret needs `forgejo admin auth update-oauth`, see Known
+          # effects). The callback URL on the Keycloak side must be
+          # /user/oauth2/Keycloak/callback — it embeds the source NAME.
+          ${forgejoCmd} admin auth list | grep -q Keycloak || \
+            ${forgejoCmd} admin auth add-oauth \
+              --name=Keycloak \
+              --provider=openidConnect \
+              --key=forgejo \
+              --secret="$(tr -d '\n' < ${keycloakSecret.path})" \
+              --auto-discover-url=https://account.ritter.family/realms/homelab/.well-known/openid-configuration \
+              --scopes=openid,email,profile
         '';
```

Why `--scopes=openid,email,profile` with commas: Forgejo 15's `--scopes`
is a urfave/cli v3 `StringSliceFlag`, and its values are split on
commas only (verified against urfave/cli v3.7.0, the version Forgejo
15.0.10 pins). A space-separated string (`--scopes='openid email
profile'`) would become a *single* bogus scope literal. All flags were
verified against the installed binary (`forgejo admin auth add-oauth
--help` on the srv-prod-6 package build): `--key`,
`--secret`, `--auto-discover-url`, `--name`, `--provider`.

### B.3 Verify, merge, apply, switch

```bash
cd tofu/keycloak
tofu fmt -check     # ✅ exit 0 locally
tofu validate       # ✅ Success — configuration is valid (provider plugins already fetched)
tofu init           # uses the state-bucket credentials from .envrc (direnv)
tofu plan           # ⏳ expected: + keycloak_openid_client.forgejo, nothing else
```

`nix flake check && nix fmt` from the repo root, then open the PR: the
pipeline's plan comment must show `+ keycloak_openid_client.forgejo`
only. A `401` there means Keycloak rejected the provider credentials —
confer the token check in the archived plan's section 1.5, step 6.

Merge; the pipeline applies the client to the `homelab` realm, and comin
switches srv-prod-6. `preStart` then creates the auth source:

```bash
ssh root@srv-prod-6.ritter.family \
  'journalctl -u forgejo --since "-10min" --no-pager | grep -iE "keycloak|auth" | tail'
# `forgejo` is on the unit's PATH, not the host's — resolve it from the unit:
ssh root@srv-prod-6.ritter.family \
  '$(systemctl show forgejo -p ExecStart --value | grep -oE "/nix/store/[^ ]*bin/forgejo") admin auth list'
```
### B.4 End-to-end login (the goal)

Fresh/incognito window → `https://git.ritter.family` → the login page
shows a **Keycloak** SSO button → click → redirect to
`account.ritter.family/realms/homelab` → sign in as `bene` → back in
Forgejo, signed in as `britter` — linked by e-mail, no local password
asked (`ACCOUNT_LINKING = "auto"`), never auto-registered because the
e-mail match resolves first.

### B.5 Rollback (Part B)

`git revert`; comin switches Forgejo back (the SSO button disappears,
password login alone remains), and the pipeline apply **deletes the
Keycloak client** — state-based, no manual Keycloak action needed.
Forgejo's auth source stays in its database pointing at a missing
client; it is inert. Remove it if it bothers anyone:
`forgejo admin auth delete <id>` (or the admin UI). The stored client
secret in both sops files can stay until the next rotation.

## Known effects

- **Forgejo restarts on secret rotation.** All forgejo sops secrets
  carry `restartUnits = [ "forgejo.service" ]` — rotating any of them
  (SMTP creds included) restarts the unit, which is required because
  `preStart` and `LoadCredential` bind values at unit start. A switch
  that only rotates a secret therefore makes Forgejo bounce for a few
  seconds; controlled by comin's activation.
- **The auth source is create-once.** `preStart` creates the source only
  if it's missing and never touches it afterwards (grep-guard). A
  rotated **client secret** therefore needs one manual step after the
  pipeline apply:
  `forgejo admin auth update-oauth --id=<id from 'forgejo admin auth list'> --secret="$(cat /run/secrets/forgejo/keycloak-client-secret)"`
  — or edit it in the Forgejo admin UI under Authentication → Keycloak.
  Run it *after* the apply, not before.
- **The client secret lives in two sops files and in tofu state.**
  Operator-generated, because it must be identical in stores nothing can
  cross-read (`secrets.json` for the CI apply, srv-prod-6's yaml for the
  `preStart`; Keycloak would generate one server-side otherwise, and the
  provider pulls it into state regardless — but then Forgejo's copy
  would have no git source of truth). Git is authoritative: the console
  *Regenerate secret* button is break-glass only, because apply
  re-sends the state value — mirror the regenerated value into
  `secrets.json` (`sops set`) or the next plan observes the diff and the
  next apply reverts the regeneration.
- **Mail now sends from `git@ritter.family`.** The Brevo key is shared
  with nothing (one key per service); activation mails and future
  password-reset mails to Forgejo users come from this sender. The
  `git@ritter.family` sender must stay validated in Brevo.
- **Transient SSO unavailability on Keycloak deploys.** Every srv-prod-1
  switch restarts Keycloak (~15–30 s); during that window, SSO redirects
  fail briefly. Password login into Forgejo is unaffected. Covered by
  the Keycloak plan (archived) — its "Known effects" section has the
  gatus story.

## References searched

Changed:

- `modules/nixos/forgejo.nix` — Part A (sops block at top with
  `restartUnits`, mailer settings, `secrets.mailer` wrapper) and Part B
  (`oauth2_client` settings, `preStart` auth source, client-secret sops
  key)
- `modules/hosts/srv-prod-6/secrets.yaml` — `["forgejo"]["smtp-username"]`,
  `["forgejo"]["smtp-password"]` (Part A, done), and
  `["forgejo"]["keycloak-client-secret"]` (Part B) via `sops set`; all
  values below the existing `forgejo:` mapping
- `tofu/keycloak/main.tf` — Part B: `keycloak_openid_client.forgejo`
  (appended to the root that PR 3 created)
- `tofu/keycloak/secrets.json` — Part B: `forgejo_client_secret`
- `docs/plans/archive/2026-10-29-keycloak-sso-on-srv-prod-1.md` — the
  keycloak plan was completed and archived when this plan took over the
  first-client work; `tofu/keycloak/README.md` points at both plans

Deliberately unchanged, with reasons:

- **DNS (`tofu/dns`)**: `*.ritter.family` points at directions via the
  global wildcard; `git` needs no new record.
- **`services.https-proxy` on srv-prod-6**: already fronts Forgejo with
  `git.ritter.family` (alias on the per-host vhost), `maxBodySize 512M`;
  OAuth2 callbacks need nothing extra (plain browser flow).
- **gatus / homepage**: Forgejo monitoring and the dashboard card exist;
  the known effects above cover new failure modes, not new endpoints.
- **`.github/workflows`**: the `OpenTofu Keycloak` pipeline (keys on
  `tofu/keycloak/**`) exists since PR 3 and picks the Part B apply up
  automatically; no new workflow.
- **`.sops.yaml` and `tofu/.sops.yaml`**: existing rules already cover
  `modules/hosts/srv-prod-6/secrets.yaml` (framework-13 + srv-prod-6)
  and `*/secrets.json` (framework-13 + github-runners).
- **Forgejo local settings beyond `oauth2_client`**: `DISABLE_SSH`
  (srv-prod-6), `DISABLE_REGISTRATION = true`, and the rest stay as
  they are — SSO rides on top of password auth, it doesn't replace the
  module's basics.
- **Keycloak realm config**: no registration flows to tighten — the
  realm already has `registration_allowed = false` (archived plan,
  PR 3), which is what makes `ENABLE_AUTO_REGISTRATION` safe.

## Follow-ups (after the rollout)

- **Split `tofu/keycloak/main.tf`** — it holds the realm, the users, and
  (since Part B) the first client; one file per concern makes the root
  scale. Target layout mirrors the repo's other tofu roots (proxmox
  keeps one file per host; dns splits per provider directory):
  `realm.tf` (realm + SMTP config), `users.tf` (personal identities),
  `client-forgejo.tf` (per-service files; future clients get one file
  each). Move with `git mv`, not delete-and-recreate. The split is
  state-neutral — no import, no state surgery — and its `tofu plan`
  must print **No changes.** to prove that. Timing: after
  `bene-fullname`'s `main.tf` edits land *and* Part B is verified in
  production (B.4), so the split PR carries zero behavior.

## Status

- ✅ Repository exploration: Forgejo 15.0.10 on srv-prod-6 (package flags
  verified from the installed binary), nixpkgs forgejo module's
  `services.forgejo.secrets` env-to-ini wrapper confirmed, restartUnits
  confirmed in the pinned sops-nix
- ✅ A.1 SMTP secrets stored and nesting verified (dashed keys under
  `forgejo:`; underscore miskeys cleaned up)
- ✅ A.2 module changes verified: `nix flake check` all-pass,
  `preStart`/app.ini evaluated, `restartUnits` resolved per secret
- ✅ A.3 merged; comin switched srv-prod-6; the admin UI (Site
      Administration → Configuration → Mailer Configuration) shows
      protocol `smtp+starttls`, `smtp-relay.brevo.com:587`, and the SMTP
      login; the built-in "Send test email" delivered a test mail
      (2026-10-29) — the mailer works end to end
- ⏳ A.4 e-mail click-ops on `britter` (in progress): set
      `beneritter@gmail.com`, complete the activation mail, make it
      primary — gate for Part B
- ⏳ B.1 client secret stored twice (`secrets.json` +
  srv-prod-6 yaml; nested paths)
- ✅ B.2 Part B code prepared on the `forgejo-sso` branch (tofu client
  resource + forgejo SSO bits): `nix flake check` all-pass,
  `tofu fmt -check` exit 0, `tofu validate` Success, `preStart` and
  app.ini `[oauth2_client]` evaluated, client-secret sops wiring with
  `restartUnits` verified
- ⏳ B.3 merged/applied/switched: pipeline plan comment shows
  `+ keycloak_openid_client.forgejo` only, comin switches srv-prod-6,
  `preStart` creates the auth source (journal + `admin auth list`)
- ⏳ B.4 first SSO login lands in `britter`
