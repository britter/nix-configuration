# Keycloak SSO on srv-prod-1, client config in tofu

**Status: complete (2026-10-29), archived per AGENTS.md. Keycloak is in production: IdP
reachable (gatus green), persistent master-realm admin + `tofu`
service-account client (section 1.5), restic backup and the proxy
header-buffer fix (PR 2), realm `homelab` with the `bene` user and
Brevo realm SMTP (PR 3; the forgot-password flow verified mail end to
end). Correction (2026-10-29): the realm was named `homelab` in PR 3
(display name `ritter.family`), not `ritter` as drafted below — the
remainder of that section is a historical record.

The first-client work (Forgejo) was split out mid-execution because its
rollout order is constrained — Forgejo's SMTP mailer must be live and
the account e-mail activated before any SSO behavior ships — and now
lives in
[`docs/plans/archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md`](2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md).
This archive covers the Keycloak deployment itself (PRs 1–3).**

## Chosen approach

Deploy Keycloak 26.8.1 (nixpkgs `services.keycloak`) on `srv-prod-1` behind the
per-host nginx (`services.https-proxy`), and manage the realm and all future
OIDC clients in a new tofu root `tofu/keycloak` using the official
`keycloak/keycloak` provider. The canonical frontend URL is
`https://account.ritter.family` (served by `directions`, targeting the per-host
vhost `https://account.srv-prod-1.ritter.family`, which targets Keycloak on
`127.0.0.1:8080`). The issuer URL is therefore decoupled from the host — if
Keycloak ever moves off srv-prod-1 (as the Beszel hub did), every client's
configured issuer keeps working. The provider authenticates with its own
service-account client in the master realm (client-credentials grant — the
provider docs' recommended setup), so no human credential is machine-read.
Realm e-mail (invite links, password resets) goes through the Brevo SMTP
account that vaultwarden on srv-prod-2 already uses, sending from
`account@ritter.family` — configured on the realm via tofu, because
Keycloak 26 has no server-wide SMTP setting (mail is realm data stored in
the database, and `services.keycloak.settings` has no SMTP keys. Forgejo on srv-prod-6
(`git.ritter.family`) is the first OIDC client: the tofu root manages its
client, and the Forgejo module declares the OAuth2 authentication source
that its `preStart` creates idempotently (PR 4 — split out mid-execution,
see the Forgejo plan linked in the status above).

Alternatives considered: Pocket ID was rejected because its only tofu
provider is a small community project covering OIDC clients only, which would
leave users/groups/passkeys hand-configured — a hard requirement against.
Authelia/Authentik were not considered; the requirement was Keycloak vs
Pocket ID.

## Why these PRs

Applies and switches both happen after merge: tofu pipelines apply on `main`,
and comin switches each server when `main` moves. That creates ordering
constraints that a single PR cannot guarantee:

1. **PR 1** deploys the IdP and creates the Garage buckets/keys that later
   phases consume. srv-prod-1's switch only needs the two new keycloak
   secrets, which are added to its `secrets.yaml` before the PR goes up.
2. **PR 2** adds the restic backup, raises the proxy header buffer on both
   Keycloak proxy hops (section 1.6), and drops the bootstrap-admin env
   (dead weight after section 1.5). It references the Garage key
   `restic-keycloak`, whose credentials only exist after PR 1's
   object-storage apply — and every sops secret referenced by the Nix config
   must exist in `secrets.yaml` before the switch, or activation fails and
   the host stays on its old generation.
3. **PR 3** adds the tofu root. Its pipeline `plan` needs a reachable
   Keycloak with the service-account credentials from section 1.5 (done),
   and its `init` needs the `tofu-states-keycloak` bucket from PR 1's apply.
4. **PR 4** (first OIDC client, Forgejo) was split out mid-execution —
   see the Forgejo plan linked in the status above. Its ordering
   rationale stands: the Keycloak-side client resource needed the realm
   from PR 3's apply in the tofu state.

PR 2 and PR 3 are independent of each other and can go up in parallel.

## References searched

Changed (PR 1):

- `modules/nixos/keycloak.nix` — new generic aspect
- `modules/hosts/srv-prod-1/services/keycloak.nix` — new per-host instance
- `modules/hosts/srv-prod-1/configuration.nix` — import the instance
- `modules/hosts/directions/services/https-proxy.nix` — public `sso` entry
- `modules/nixos/gatus.nix` — health endpoint
- `modules/nixos/homepage.nix` — dashboard card
- `tofu/object-storage/garage/variables.tf` — state bucket/key and restic
  bucket/key for keycloak
- `tofu/keycloak/secrets.json` — sops-encrypted provider credentials
  (rotated in section 1.5)

Changed (PR 2):

- `modules/hosts/srv-prod-1/services/keycloak.nix` — restic backup of the
  Postgres dump
- `modules/nixos/https-proxy.nix` — new `proxyHeaderBufferSize` option
  (constraint-safe `proxy_buffer_size` + `proxy_busy_buffers_size` pair,
  section 1.6)
- `modules/nixos/keycloak.nix` — drop the bootstrap-admin env (section 1.5)
  and raise the header buffer on the Keycloak vhost (section 1.6)
- `modules/hosts/directions/services/https-proxy.nix` — header buffer for
  the `account.ritter.family` vhost (section 1.6)
- `modules/hosts/srv-prod-1/secrets.yaml` — restic credentials (via `sops set`)

Changed (PR 3):

- `tofu/keycloak/` — new root (`provider.tf`, `main.tf`, `.envrc`,
  `README.md`; `secrets.json` is already on main since PR 1)
- `.github/workflows/tofu-keycloak.yaml` — new pipeline
- `tofu/README.md` — root list

Changed by the Forgejo plan (split out): see
docs/plans/archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md.

Deliberately unchanged, with reasons:

- **DNS (`tofu/dns`)**: `*.ritter.family` already points at directions via the
  global wildcard (`tofu/dns/cloudflare/directions.tf`), and
  `host_wildcard` already creates `*.srv-prod-1.ritter.family`. `sso` needs
  no record.
- **VM (`tofu/proxmox/srv-prod-1.tf`)**: already provisioned; 2 cores / 4 GB
  is enough for Keycloak 26 + a small Postgres.
- **Firewall**: `services.https-proxy` opens 80/443 on srv-prod-1; Keycloak
  binds `127.0.0.1:8080` and is not externally reachable.
- **`.sops.yaml` / `tofu/.sops.yaml`**: existing rules already cover
  `modules/hosts/srv-prod-1/secrets.yaml` (framework-13 + srv-prod-1) and any
  `*/secrets.json` (framework-13 + github-runners).
- **Actions allow-list**: PR 3 reuses `actions/checkout` and
  `actions/github-script`; no new third-party action.
- **`restic-restore`**: srv-prod-1 gets it via `system-server`; no change.
- **Master realm e-mail**: only the `ritter` realm gets SMTP (PR 3). Realm
  e-mail is per-realm by design, and master-realm users never receive mail.
- **Brevo SMTP keys**: dashboard-managed. Brevo's API does not expose SMTP
  key management (the community `bbieniek/brevo` provider covers senders,
  domains, templates, webhooks — but not keys), so keys are created once
  per service in the dashboard and stored in sops; everything that *uses*
  them is tofu-managed (the realm's SMTP config, PR 3). Managing Brevo
  senders via `bbieniek/brevo` was considered and declined for now: the
  required API key is a far bigger secret than an SMTP key.

## PR 1 — deploy the IdP

### ✅ 1.1 Prepare secrets (idempotent: no — `sops set` overwrites; run once)

Values below are placeholders. Generate and pipe them; never paste from a
clipboard or a plan. Run on framework-13 (it is in srv-prod-1's key group).

`sops set` parses its value as JSON even when the value comes via
`--value-stdin`, so every value is JSON-quoted with `jq -R .` on the way in.
Piping also keeps the secret out of the process list, which the argument
form does not. Verified with a throwaway age key: `sops set` also creates
missing nested keys, but a malformed key path or empty stdin silently fails
or creates a misspelled key, so check the block afterwards (verify command
below).

```bash
KC_ADMIN_PW=$(openssl rand -base64 24 | tr -d '/+=')
KC_DB_PW=$(openssl rand -base64 24 | tr -d '/+=')

echo "$KC_ADMIN_PW" | jq -R . | sops set modules/hosts/srv-prod-1/secrets.yaml \
  '["keycloak"]["admin-password"]' --value-stdin
echo "$KC_DB_PW" | jq -R . | sops set modules/hosts/srv-prod-1/secrets.yaml \
  '["keycloak"]["database-password"]' --value-stdin

# Same admin password, encrypted for the tofu root (committed in PR 3).
# sops picks the nearest .sops.yaml walking UP from the current working
# directory — run from the repo root it finds the root .sops.yaml, which has
# no rule for secrets.json ("no matching creation rules found"). Run it from
# inside the root so tofu/.sops.yaml is found; its generic rule
# (`.*/secrets\.json$`) also requires a slash in the matched path, so the
# --filename-override must be directory-qualified (`keycloak/secrets.json`,
# not bare `secrets.json`).
mkdir -p tofu/keycloak
jq -n --arg u admin --arg p "$KC_ADMIN_PW" \
  '{keycloak_url:"https://account.ritter.family",
    keycloak_admin_username:$u,
    keycloak_admin_password:$p}' \
  | (cd tofu/keycloak && sops -e --filename-override keycloak/secrets.json /dev/stdin \
      > secrets.json)

unset KC_ADMIN_PW KC_DB_PW
```

(Superseded by section 1.5: it removes both `keycloak_admin_*` keys and
stores the tofu service-account client credentials instead; the host's
`keycloak/admin-password` is dropped in step 2.3.)

Verify:

```bash
sops -d modules/hosts/srv-prod-1/secrets.yaml | grep -A2 '^keycloak:'
# expected: exactly two keys under keycloak:
#   keycloak:
#       admin-password: ENC[...]
#       database-password: ENC[...]
sops -d tofu/keycloak/secrets.json | jq 'keys'
# expected: ["keycloak_admin_password","keycloak_admin_username","keycloak_url"]
```

### 1.2 Repo changes (all included in this branch)

@@ modules/nixos/keycloak.nix @@

New file. Keycloak 26 hostname-v2 semantics: with `hostname` set to a full
URL, all frontend URLs are pinned to it and `hostname-strict` is ignored
(https://www.keycloak.org/server/hostname#_validations). Edge TLS termination
requires `http-enabled` and `proxy-headers`.

```nix
_: {
  flake.modules.nixos.keycloak =
    { config, ... }:
    let
      fqdn = "account.ritter.family";
      localFqdn = "account.${config.networking.hostName}.ritter.family";
    in
    {
      services.keycloak = {
        enable = true;
        database.passwordFile = config.sops.secrets."keycloak/database-password".path;
        settings = {
          # Full URL: pins scheme, port and context path; all frontend URLs
          # use it, regardless of the vhost the request arrived at.
          hostname = "https://${fqdn}";
          # Edge TLS termination in front of Keycloak.
          http-enabled = true;
          proxy-headers = "xforwarded";
          # Bind to loopback only; nginx is the only consumer.
          http-host = "127.0.0.1";
          # nginx owns 80/443 on this host.
          http-port = 8080;
        };
      };

      sops.secrets."keycloak/database-password" = { };
      sops.secrets."keycloak/admin-password" = { };
      # Bootstrap/recovery admin. Keycloak only creates the user if it does
      # not exist, so this is inert after first start and acts as a recovery
      # path per https://www.keycloak.org/server/bootstrap-admin-recovery.
      sops.templates."keycloak-bootstrap-env".content = ''
        KC_BOOTSTRAP_ADMIN_USERNAME=admin
        KC_BOOTSTRAP_ADMIN_PASSWORD=${config.sops.placeholder."keycloak/admin-password"}
      '';
      systemd.services.keycloak.serviceConfig.EnvironmentFile =
        config.sops.templates."keycloak-bootstrap-env".path;

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = localFqdn;
            target = "http://127.0.0.1:8080";
          }
        ];
      };
    };
}
```

@@ modules/hosts/srv-prod-1/services/keycloak.nix @@

New file, base-plus-instance pattern:

```nix
{ config, ... }:
let
  inherit (config.flake.modules.nixos) keycloak;
in
{
  flake.modules.nixos.keycloak-on-srv-prod-1 = {
    imports = [ keycloak ];
  };
}
```

@@ modules/hosts/srv-prod-1/configuration.nix @@

```diff
       system-server
       proxmox-vm
       tailscale-server
       beszel-agent
+      keycloak-on-srv-prod-1
       (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
```

@@ modules/hosts/directions/services/https-proxy.nix @@

```diff
           {
             fqdn = "pdf.ritter.family";
             target = "https://pdf.srv-prod-2.ritter.family";
             extraConfig = ''
               client_max_body_size 100M;
             '';
           }
+          {
+            fqdn = "account.ritter.family";
+            target = "https://account.srv-prod-1.ritter.family";
+          }
           {
             fqdn = "tools.ritter.family";
             target = "https://tools.srv-prod-6.ritter.family";
           }
```

@@ modules/nixos/gatus.nix @@

```diff
             {
               name = "Beszel";
               url = "https://beszel.ritter.family/api/health";
               interval = "5m";
               conditions = [
                 "[STATUS] == 200"
               ];
             }
+            {
+              name = "SSO";
+              url = "https://account.ritter.family";
+              interval = "5m";
+              conditions = [
+                "[STATUS] == 200"
+              ];
+            }
             {
               name = "Forgejo";
```

@@ modules/nixos/homepage.nix @@

Keycloak goes into the Infrastructure group (after Adguard; the group is
not strictly sorted today).

```diff
             {
               "Adguard" = {
                 description = "Network-wide ads & trackers blocking DNS server";
                 href = "https://adguard.ritter.family/";
                 icon = "adguard-home.svg";
               };
             }
+            {
+              "Keycloak" = {
+                description = "Single sign-on";
+                href = "https://account.ritter.family/";
+                icon = "keycloak.svg";
+              };
+            }
             {
               "FritzBox" = {
```

@@ tofu/object-storage/garage/variables.tf @@

```diff
 variable "managed_tofu_projects" {
   type    = list(string)
-  default = ["domains", "dns", "network", "proxmox"]
+  default = ["domains", "dns", "network", "proxmox", "keycloak"]
 }
```

and

```diff
 variable "restic_backups" {
   type    = list(string)
-  default = ["git", "nextcloud", "vaultwarden", "calibre", "forgejo", "paperless"]
+  default = ["git", "nextcloud", "vaultwarden", "calibre", "forgejo", "paperless", "keycloak"]
 }
```

The restic bucket/key are created here (PR 1 apply) but only consumed by
PR 2; creating them early removes the ordering race described above.

### 1.3 Verify locally, then merge

```bash
nix flake check   # PASSED (evaluates srv-prod-1 and directions with the new aspects)
nix fmt           # clean
```

Open PR 1, check the object-storage pipeline plan comment (eight new
resources, all keyed `["keycloak"]`, additions only: buckets
`tofu-states-keycloak` and `restic-keycloak`; keys `tofu-keycloak` and
`restic-keycloak`; and four key×bucket grants — rw+owner for each service
key on its bucket, plus read-only grants for the restore and global-read
keys on restic-keycloak. Garage has no IAM policies, so every key×bucket
pair is its own grant resource), merge.

### 1.4 Post-merge checks (phase boundary)

comin switches both servers within a few minutes of the merge; the
object-storage apply runs in parallel.

```bash
ssh root@srv-prod-1.ritter.family systemctl is-active keycloak postgresql
# expected: active / active
curl -s https://account.ritter.family/ | head -1
# expected: HTML doctype of the Keycloak login page
curl -s https://account.ritter.family/realms/master/.well-known/openid-configuration | jq -r .issuer
# expected: https://account.ritter.family/realms/master
```

Then log in at `https://account.ritter.family` as `admin` with the generated
admin password to verify the console is reachable, and continue with
section 1.5 — the temporary bootstrap account is replaced there, not left
in place (an earlier revision of this plan said to keep it for tofu; that
no longer holds). Check that gatus shows the SSO endpoint green at
`https://status.ritter.family`.

**Rollback (PR 1):** `git revert` the PR; comin switches back. The new
buckets/keys in Garage are inert and can stay. The Keycloak state
(Postgres data under `/var/lib/postgresql`) is disposable at this point —
no clients exist yet.

### 1.5 One-time hardening: replace the temporary bootstrap admin (click-ops)

Keycloak flags the account created from `KC_BOOTSTRAP_ADMIN_*` as
**temporary**: the console shows the hardening banner on every login, and
the server honors those variables only during the very first start, when
the master realm does not exist yet
(https://www.keycloak.org/server/bootstrap-admin-recovery). Two
consequences the original plan got wrong:

- Deleting the temporary `admin` user is safe and permanent — it is *not*
  recreated on restart, even while the environment file is still wired into
  the service. The wiring (removed in PR 2) is dead weight, not a recovery
  path.
- The real break-glass path is the dedicated `kc.sh bootstrap-admin user`
  command, run manually against the stopped server (documented in the
  tofu/keycloak README, PR 3).

The plan originally assumed the bootstrap account would double as the tofu
admin. That keeps the banner (and a shared, MFA-less password) around
forever, so it is replaced by a persistent human admin plus a dedicated
service-account client for the provider — the setup the provider docs
recommend ("the client credentials grant is recommended, as it was designed
for machine to machine authentication"). All console steps are one-time
click-ops in the master realm; the sops step runs on framework-13.

1. Create the persistent admin user (Users → *Create user*): `bene` (pick
   any username), your real email. **Credentials** → *Set password* from
   the password manager, *Temporary* off; **Role mapping** → *Assign role*
   → filter by realm roles → check `admin` → *Assign*. The master realm's
   `admin` realm role is the superuser role (full access to all realms).
   A second factor can be added to this account later without affecting
   the provider.

2. Create the provider client (Clients → *Create client*): Client type
   *OpenID Connect*, Client ID `tofu`; turn *Client authentication* ON
   (confidential), *Standard flow* and *Direct access grants* OFF, and
   service accounts ON (*Service accounts roles*) — the provider docs'
   client-credentials setup. Then, in the client's **Service accounts
   roles** tab: *Assign role* → filter by realm roles → `admin`
   ("Managing the entire Keycloak instance: assign the `admin` role to a
   user or service account within the `master` realm"). Copy the secret
   from the **Credentials** tab. The journal then logs a deprecation
   warning about this client's "Full scope allowed" switch — leave it
   enabled: it is what keeps the `admin` realm role in the provider's
   tokens (disabling it would require mapping the role into the client's
   dedicated scope; no benefit for an instance-wide admin client).

3. Store the client credentials in `tofu/keycloak/secrets.json` (keep the
   key names — `provider.tf` reads exactly these), and drop the bootstrap
   keys written in step 1.1:

   ```bash
   printf 'tofu' | jq -R . | \
     sops set tofu/keycloak/secrets.json '["keycloak_admin_client_id"]' --value-stdin
   read -rs -p "Secret of client 'tofu': " KC_CLIENT_SECRET; echo
   printf '%s' "$KC_CLIENT_SECRET" | jq -R . | \
     sops set tofu/keycloak/secrets.json '["keycloak_admin_client_secret"]' --value-stdin
   unset KC_CLIENT_SECRET
   sops unset tofu/keycloak/secrets.json '["keycloak_admin_username"]'
   sops unset tofu/keycloak/secrets.json '["keycloak_admin_password"]'
   ```

4. Log out, log back in as the new admin user: no banner, *Create realm*
   button present.
5. Delete the temporary `admin` user (Users → `admin` → *Delete*). Safe and
   permanent per the docs link above.
6. Verify the provider credentials (this is exactly the grant the tofu
   provider uses — client credentials on the master realm). All three
   values must come from the file, like the provider reads them — a check
   that hardcodes the client id would mask a typo in the file:

   ```bash
   cd tofu/keycloak   # check the file the provider actually reads
   id=$(sops -d secrets.json | jq -r .keycloak_admin_client_id)
   url=$(sops -d secrets.json | jq -r .keycloak_url)
   curl -s "$url/realms/master/protocol/openid-connect/token" \
     -d grant_type=client_credentials -d "client_id=$id" \
     --data-urlencode client_secret="$(sops -d secrets.json | jq -r .keycloak_admin_client_secret)" \
     | jq -r 'if .access_token then "ok" else . end'
   # expected: ok; anything else is the token endpoint's error object:
   # invalid_client — client id or secret in the file doesn't match Keycloak
   # unauthorized_client — the client lacks "Service accounts roles"
   ```

   If the CI plan 401s where this check passes, compare what each runs
   against — and read the exact failure reason in the admin console
   (master realm → Events → Login events: `client_not_found`, secret
   mismatch, or a capability problem).

The personal identity (`bene` in the `ritter` realm) is not created here —
it is tofu-managed in PR 3 (`keycloak_user`), and it is deliberately a
separate, unprivileged account: the master-realm admin is for the admin
console only, while application logins happen in the `ritter` realm. Users
are realm-local, so apps pointed at the `ritter` issuer only ever accept
`ritter` users — the admin account cannot become an app identity, and a
compromised application exposes `bene`, not the superuser. Reusing the
username `bene` in both realms is fine: uniqueness is per realm, and the
two accounts share nothing (credentials, sessions, roles). Tofu covers the
user data (username, email), but not the password: `keycloak_user` could
set an `initial_password`, yet the plain value would land in the tofu
state file, so passwords are set by the user — via the console or the
forgot-password mail.

Must be complete before PR 3 is opened: the pipeline's `plan`/`apply`
authenticate with `secrets.json`, which now holds the client credentials.

**Rollback (section 1.5):** nothing in git to revert. If an admin login is
locked out mid-run, use the break-glass command (tofu/keycloak README) and
redo the failed step.

### 1.6 Known issue: 502 on "Manage account" (diagnosed — fix in PR 2)

Clicking *Manage account* in the admin console (master realm) redirects to
the master realm's account console and ends in an nginx 502. Everything
else works — the token endpoint returned `ok` in step 1.5.6, the admin
console and login pages work — so Keycloak is up, and the failure is
specific to the one request where Keycloak hands the browser back its full
cookie bundle (`KEYCLOAK_IDENTITY`, `KEYCLOAK_SESSION`, `AUTH_SESSION_ID`,
plus a `KC_RESTART` cookie fattened by the double-encoded `referrer_uri`
deep-link).

Confirmed 2026-10-28 in directions' nginx journal:

```
upstream sent too big header while reading response header from upstream
... server: account.ritter.family ... upstream: "https://192.168.30.11:443/realms/master/..."
```

The response header block exceeds nginx's default `proxy_buffer_size`
(4 KB — the https-proxy module sets no override). srv-prod-1's own nginx
hop and Keycloak are clean, but the same header bundle rides both hops, so
the buffer is raised on **both** account vhosts (diffs in step 2.2):
directions' `account.ritter.family` entry and the srv-prod-1 Keycloak
instance's vhost. Until PR 2 switches, *Manage account* keeps 502ing —
cosmetic; nothing depends on the master account console.

**Correction (same day):** the first fix raised `proxy_buffer_size 16k`
**alone** — invalid nginx config. nginx derives its default
`proxy_busy_buffers_size` as 2 × max(`proxy_buffer_size`, one
`proxy_buffers` buffer) = 32k, and that violates nginx's constraint
`proxy_busy_buffers_size` must be less than the size of all
`proxy_buffers` minus one buffer (default `proxy_buffers` 8 × 4k → 28k
ceiling); `nginx -t` fails with exactly that emerg. A failed reload
keeps the old config in memory, so the 502 fix *appeared* to work after
the PR 2 switches — until nginx's next restart, which took directions'
nginx down (`connect: connection refused` from the runner mid-PR-3
debugging). The https-proxy module now has a `proxyHeaderBufferSize`
option emitting the constraint-safe pair (`proxy_buffer_size` +
`proxy_busy_buffers_size`, both 16k), used by both account vhosts.

Must be merged before step 3.4 — the account-console flows (logging into
the account console, forgot-password) take the same response path in the
`ritter` realm.

## PR 2 — backups, the 502 fix, and admin cleanup

### 2.1 Prepare restic secrets (idempotent: no — run once, after PR 1's object-storage apply)

The credential maps are child-module outputs
(`tofu/object-storage/garage/outputs.tf`), which `tofu output` cannot
reach — pull them from the state instead. `cd` into the root first:
`-chdir` does not fire direnv, so the state-bucket credentials would be
missing.

```bash
cd tofu/object-storage   # direnv loads this root's state-bucket credentials
state=$(tofu state pull)
cd ../..

# Garage key attributes are access_key_id / secret_access_key.
restic_id=$(echo "$state" | jq -r '.resources[] | select(.module=="module.srv-prod-3-garage" and .type=="garage_key" and .name=="restic_users") | .instances[] | select(.index_key=="keycloak") | .attributes.access_key_id')
restic_secret=$(echo "$state" | jq -r '.resources[] | select(.module=="module.srv-prod-3-garage" and .type=="garage_key" and .name=="restic_users") | .instances[] | select(.index_key=="keycloak") | .attributes.secret_access_key')

# jq without -r emits the value as a JSON string, which is exactly what
# sops set --value-stdin expects.
echo "$restic_id" | jq -R . | sops set modules/hosts/srv-prod-1/secrets.yaml \
  '["restic"]["keycloak"]["garage-access-key-id"]' --value-stdin
echo "$restic_secret" | jq -R . | sops set modules/hosts/srv-prod-1/secrets.yaml \
  '["restic"]["keycloak"]["garage-secret-access-key"]' --value-stdin
openssl rand -base64 24 | tr -d '/+=' | jq -R . | sops set modules/hosts/srv-prod-1/secrets.yaml \
  '["restic"]["keycloak"]["repository-password"]' --value-stdin

unset state restic_id restic_secret
```

### 2.2 Repo changes

@@ modules/hosts/srv-prod-1/services/_restic-constants.nix @@

New file, identical to srv-prod-2's (same Garage endpoint, same retention):

```nix
{
  bucket-prefix = "s3:https://garage.srv-prod-3.ritter.family/restic";
  pruneOpts = [
    "--keep-daily 14"
    "--keep-weekly 8"
    "--keep-monthly 12"
    "--keep-yearly 5"
  ];
  timerConfig = {
    OnCalendar = "00:00";
    RandomizedDelaySec = "30m";
    Persistent = true;
  };
}
```

@@ modules/hosts/srv-prod-1/services/keycloak.nix @@

```diff
 { config, ... }:
 let
   inherit (config.flake.modules.nixos) keycloak;
+  restic = import ./_restic-constants.nix;
 in
 {
   flake.modules.nixos.keycloak-on-srv-prod-1 =
+    {
+      config,
+      lib,
+      pkgs,
+      ...
+    }:
     {
       imports = [ keycloak ];
+
+      systemd.tmpfiles.rules = [
+        "d /var/backups/keycloak 0750 postgres postgres"
+      ];
+
+      sops.secrets."restic/keycloak/repository-password" = { };
+      sops.secrets."restic/keycloak/garage-access-key-id" = { };
+      sops.secrets."restic/keycloak/garage-secret-access-key" = { };
+      sops.templates."restic/keycloak/env" = {
+        content = ''
+          AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic/keycloak/garage-access-key-id"}
+          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic/keycloak/garage-secret-access-key"}
+          RESTIC_PASSWORD=${config.sops.placeholder."restic/keycloak/repository-password"}
+        '';
+      };
+
+      services.restic.backups.keycloak =
+        let
+          pg_dump = "${config.services.postgresql.package}/bin/pg_dump";
+        in
+        {
+          environmentFile = config.sops.templates."restic/keycloak/env".path;
+          paths = [ "/var/backups/keycloak" ];
+          repository = "${restic.bucket-prefix}-keycloak";
+          initialize = true;
+          backupPrepareCommand = ''
+            ${lib.getExe pkgs.sudo} -u postgres ${pg_dump} --format=custom --file=/var/backups/keycloak/keycloak.dump keycloak
+          '';
+          backupCleanupCommand = ''
+            rm /var/backups/keycloak/keycloak.dump
+          '';
+          inherit (restic) pruneOpts timerConfig;
+        };
     };
 }
```

@@ modules/nixos/keycloak.nix @@

Remove the bootstrap-admin wiring entirely. The environment file is only
honored on the very first start (when the master realm is created), so it
never was a recovery path — the comment in the PR 1 module was wrong; the
real recovery path is the `bootstrap-admin` command (section 1.5, and the
tofu/keycloak README). The temporary `admin` user it created was deleted in
section 1.5.

```diff
       sops.secrets."keycloak/database-password" = { };
-      sops.secrets."keycloak/admin-password" = { };
-      # Bootstrap/recovery admin. Keycloak only creates the user if it does
-      # not exist, so this is inert after first start and acts as a recovery
-      # path per https://www.keycloak.org/server/bootstrap-admin-recovery.
-      sops.templates."keycloak-bootstrap-env".content = ''
-        KC_BOOTSTRAP_ADMIN_USERNAME=admin
-        KC_BOOTSTRAP_ADMIN_PASSWORD=${config.sops.placeholder."keycloak/admin-password"}
-      '';
-      systemd.services.keycloak.serviceConfig.EnvironmentFile =
-        config.sops.templates."keycloak-bootstrap-env".path;

       services.https-proxy = {
         enable = true;
         configurations = [
           {
             fqdn = localFqdn;
             target = "http://127.0.0.1:8080";
+            # The account console hands back a large cookie bundle;
+            # nginx's 4k default proxy_buffer_size 502s on it ("upstream
+            # sent too big header", section 1.6). Raised on directions'
+            # vhost too.
+            proxyHeaderBufferSize = "16k";
           }
         ];
       };
```

@@ modules/hosts/directions/services/https-proxy.nix @@

Same buffer raise for the public hop — this is the hop that actually 502'd
(section 1.6):

```diff
           {
             fqdn = "account.ritter.family";
             target = "https://account.srv-prod-1.ritter.family";
+            proxyHeaderBufferSize = "16k";
           }
           {
             fqdn = "tools.ritter.family";
```

### 2.3 Verify, merge, check

```bash
nix flake check && nix fmt
```

Merge; comin switches srv-prod-1. Then force the first run:

```bash
ssh root@srv-prod-1.ritter.family systemctl start restic-backups-keycloak
ssh root@srv-prod-1.ritter.family \
  systemctl status restic-backups-keycloak
# expected: active (exited) — wait — check journal for a successful dump + restic snapshot
```

After the switch, drop the dead bootstrap password — only then: the
previous generation still declares the secret, and removing the key from
`secrets.yaml` before that switch would fail activation:

```bash
sops unset modules/hosts/srv-prod-1/secrets.yaml '["keycloak"]["admin-password"]'
```

Re-verify section 1.6: in the admin console, *Manage account* must now load
the master account console instead of 502ing.

**Rollback (PR 2):** revert; comin switches back. The restic repo in Garage
stays (harmless, will be pruned by retention once unused). If the revert
happens after the `sops unset` above, re-add the key first (any value
works; the reverted module requires it to exist) or activation fails:

```bash
echo unused | jq -R . | sops set modules/hosts/srv-prod-1/secrets.yaml \
  '["keycloak"]["admin-password"]' --value-stdin
```

## PR 3 — tofu root for realm/client management

### 3.1 Finish secrets.json (idempotent: yes — `sops set` overwrites each key)

The state-bucket credentials: same child-module-output situation as in
step 2.1 — pull from the state, from inside the root (direnv):

```bash
cd tofu/object-storage   # direnv loads this root's state-bucket credentials
state=$(tofu state pull)
cd ../..

state_id=$(echo "$state" | jq -r '.resources[] | select(.module=="module.srv-prod-3-garage" and .type=="garage_key" and .name=="state_users") | .instances[] | select(.index_key=="keycloak") | .attributes.access_key_id')
state_secret=$(echo "$state" | jq -r '.resources[] | select(.module=="module.srv-prod-3-garage" and .type=="garage_key" and .name=="state_users") | .instances[] | select(.index_key=="keycloak") | .attributes.secret_access_key')

echo "$state_id" | jq -R . | sops set tofu/keycloak/secrets.json \
  '["state_bucket_key_id"]' --value-stdin
echo "$state_secret" | jq -R . | sops set tofu/keycloak/secrets.json \
  '["state_bucket_secret_key"]' --value-stdin
unset state state_id state_secret
```

(Improvement candidate, not needed today: surface the garage module's
credential maps as root-level outputs in `tofu/object-storage/main.tf` —
the module already computes them in exactly the shape these commands
assume; `tofu output` would then replace the state-pull jq.)

Then add the Brevo SMTP credentials — the account also serves vaultwarden
on srv-prod-2, so create a separate SMTP key for Keycloak in the Brevo
dashboard (Settings → *SMTP & API*), one key per service like the Garage
keys. The SMTP login is the login shown on that page, the password is the
SMTP key. The realm sends from `account@ritter.family` — validate that
sender in the Brevo dashboard (Settings → Senders) if it does not exist
yet.

```bash
read -rs -p "Brevo SMTP login: " KC_SMTP_USER; echo
read -rs -p "Brevo SMTP key: " KC_SMTP_KEY; echo
printf '%s' "$KC_SMTP_USER" | jq -R . | sops set tofu/keycloak/secrets.json \
  '["keycloak_smtp_username"]' --value-stdin
printf '%s' "$KC_SMTP_KEY" | jq -R . | sops set tofu/keycloak/secrets.json \
  '["keycloak_smtp_password"]' --value-stdin
unset KC_SMTP_USER KC_SMTP_KEY
```

Alternative (reuse the vaultwarden credentials, no Brevo dashboard visit;
framework-13 is in srv-prod-2's key group):

```bash
sops -d modules/hosts/srv-prod-2/secrets.yaml | jq -r '."vaultwarden/smtp-username"' \
  | jq -R . | sops set tofu/keycloak/secrets.json \
      '["keycloak_smtp_username"]' --value-stdin
sops -d modules/hosts/srv-prod-2/secrets.yaml | jq -r '."vaultwarden/smtp-password"' \
  | jq -R . | sops set tofu/keycloak/secrets.json \
      '["keycloak_smtp_password"]' --value-stdin
```

### 3.2 Repo changes

@@ tofu/keycloak/provider.tf @@ (new file)

```hcl
terraform {
  backend "s3" {
    bucket                      = "tofu-states-keycloak"
    key                         = "terraform.tfstate"
    region                      = "garage"
    endpoint                    = "https://garage.srv-prod-3.ritter.family"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.10.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}

provider "sops" {}

data "sops_file" "secrets" {
  source_file = "secrets.json"
}

# Official provider, hosted under the keycloak org since 2024-12.
# Client-credentials grant against the `tofu` service-account client in the
# master realm (section 1.5) — the provider docs' recommended setup.
provider "keycloak" {
  client_id     = data.sops_file.secrets.data["keycloak_admin_client_id"]
  client_secret = data.sops_file.secrets.data["keycloak_admin_client_secret"]
  url           = data.sops_file.secrets.data["keycloak_url"]
  # Required for servers >= 26.4 (provider fails version parsing otherwise).
  # Keep in sync with the nixpkgs keycloak version; renovate bumps both.
  keycloak_version = "26.8.1"
}
```

@@ tofu/keycloak/main.tf @@ (new file)

```hcl
resource "keycloak_realm" "ritter" {
  realm        = "ritter"
  display_name = "Ritter"
  enabled      = true

  # Conservative defaults; open up deliberately when a feature is needed.
  registration_allowed = false
  # "Forgot password?" on the login page — the reason this realm gets SMTP
  # in the same PR (without mail the reset link is a dead end).
  reset_password_allowed = true
  # Flip on when wanted: forces email verification on first login and after
  # address changes. Invites work without it (the admin console sends the
  # verify/set-password mails as required actions).
  verify_email = false

  ssl_required = "external"

  # Outgoing mail via the Brevo account that also serves vaultwarden on
  # srv-prod-2 (own SMTP key, credentials in secrets.json). Keycloak 26 has
  # no server-wide SMTP setting — mail is realm data, so the realm resource
  # is the only place to manage it. The provider reads the password back
  # from the API, so plans stay drift-free; the value does end up in the
  # tofu state in Garage, whose bucket is readable by exactly the hosts
  # that can decrypt secrets.json (framework-13 + github-runners).
  smtp_server {
    host              = "smtp-relay.brevo.com"
    port              = "587"
    from              = "account@ritter.family"
    from_display_name = "Ritter Account"
    starttls          = true

    auth {
      username = data.sops_file.secrets.data["keycloak_smtp_username"]
      password = data.sops_file.secrets.data["keycloak_smtp_password"]
    }
  }
}

# Personal identities, managed like everything else. No password here —
# passwords are set by the user via the console or the forgot-password
# mail; an initial_password would land in the tofu state (section 1.5).
resource "keycloak_user" "bene" {
  realm_id = keycloak_realm.ritter.id
  username = "bene"
  enabled  = true

  email          = "bene@example.com" # your real address
  email_verified = true
}
```

@@ tofu/keycloak/.envrc @@ (new file — identical to the other roots)

```bash
use flake

if secrets=$(sops -d secrets.json 2>/dev/null); then
  export AWS_ACCESS_KEY_ID=$(echo "$secrets" | jq -r .state_bucket_key_id)
  export AWS_SECRET_ACCESS_KEY=$(echo "$secrets" | jq -r .state_bucket_secret_key)
else
  log_status "sops: cannot decrypt secrets.json on this host, skipping secret export"
fi
```

@@ tofu/keycloak/README.md @@ (new file)

Short root README: what it manages (realm `ritter` including its SMTP
config and its users — starting with the personal `bene` identity;
one `keycloak_openid_client` resource per service — Forgejo first (PR 4)), where the provider
credentials come from (`secrets.json` — the `tofu` service-account client
in the master realm from section 1.5, not a bootstrap account), the
`.envrc` flow, the note that the realm is created by tofu — if it is ever
created manually first, run `tofu import keycloak_realm.ritter ritter` —
and the break-glass procedure for lost admin access:

```bash
ssh root@srv-prod-1.ritter.family
systemctl stop keycloak
# creates a NEW temporary admin; the db options must match the service
# (db "keycloak", user "keycloak" — see `systemctl cat keycloak` for the
# rendered config). Do not reuse the section 1.1 password.
KC_DB=postgres KC_DB_USERNAME=keycloak KC_DB_PASSWORD='…' \
KC_BOOTSTRAP_ADMIN_USERNAME=temp-admin KC_BOOTSTRAP_ADMIN_PASSWORD='…' \
  kc.sh bootstrap-admin user
systemctl start keycloak
```

Then log in as `temp-admin`, restore access to the real admins (reset a
password / re-assign the `admin` role), delete `temp-admin`. `kc.sh` is on
the system PATH because the nixpkgs module adds the package to
`environment.systemPackages`.

@@ .github/workflows/tofu-keycloak.yaml @@ (new file — copy of
`tofu-proxmox.yaml` with the paths and latch renamed)

```diff
-name: OpenTofu Proxmox
+name: OpenTofu Keycloak

 on:
   push:
     branches: [main]
     paths:
-      - tofu/proxmox/**
+      - tofu/keycloak/**
       - tofu/.sops.yaml
       - modules/nix/dev-shell/**
       - modules/nix/treefmt.nix
       - modules/nix/pre-commit.nix
       - flake.nix
       - flake.lock
-      - .github/workflows/tofu-proxmox.yaml
+      - .github/workflows/tofu-keycloak.yaml
       - .github/workflows/_tofu.yaml
   pull_request:
     paths:
-      - tofu/proxmox/**
+      - tofu/keycloak/**
       - tofu/.sops.yaml
       - modules/nix/dev-shell/**
       - modules/nix/treefmt.nix
       - modules/nix/pre-commit.nix
       - flake.nix
       - flake.lock
-      - .github/workflows/tofu-proxmox.yaml
+      - .github/workflows/tofu-keycloak.yaml
       - .github/workflows/_tofu.yaml

 permissions:
   contents: read
   pull-requests: write

 jobs:
   tofu:
     uses: ./.github/workflows/_tofu.yaml
     with:
-      working-directory: tofu/proxmox
+      working-directory: tofu/keycloak
     secrets: inherit
     concurrency:
-      group: tofu_latch_proxmox
+      group: tofu_latch_keycloak
       cancel-in-progress: false
```

@@ tofu/README.md @@

Add `tofu/keycloak` to the root list, same line style as the others.

### 3.3 Verify locally (init/plan/validate are fine; never apply)

```bash
cd tofu/keycloak
nix fmt
tofu fmt -check
tofu init          # uses state bucket credentials from .envrc
tofu validate      # PASSED (syntax + provider schema)
tofu plan          # expected: + keycloak_realm.ritter, + keycloak_user.bene
```

The PR's pipeline plan comment must show the same two resources. Merge;
the pipeline applies on `main`.

Runner network path: the self-hosted runner resolves
`account.ritter.family` to directions (192.168.30.6, the front proxy)
via the LAN's DNS. A CI plan failing with `connect: connection refused`
against that address means directions' nginx is down — an operational
outage, not a tofu problem (`systemctl status nginx` on directions;
re-run the failed job once it serves again). A `401` in contrast means
the request reached Keycloak and the credentials in `secrets.json` are
being rejected — see the check in section 1.5, step 6.

### 3.4 Post-merge check

```bash
curl -s https://account.ritter.family/realms/ritter/.well-known/openid-configuration | jq -r .issuer
# expected: https://account.ritter.family/realms/ritter
```

Then verify the user and the mail path end to end:

1. Set your password on the tofu-created `bene` user: admin console →
   realm `ritter` → Users → `bene` → Credentials → *Set password*
   (Temporary off). Alternatively use *Forgot password?* on the realm's
   login page — that also smoke-tests SMTP.
2. Log in as `bene` at the account console,
   `https://account.ritter.family/realms/ritter/account`.
3. Admin console, realm `ritter` → Realm settings → Email → *Test
   connection* — the test mail goes to the logged-in admin's email address
   (the master-realm admin from section 1.5).

**Rollback (PR 3):** revert; comin is unaffected. The pipeline apply is
state-based: a revert deletes the realm on the next apply. Only do that when
no clients are enrolled yet — deleting the realm invalidates every issuer
URL that points into it.

## PR 4 — Forgejo, first client: split out

Execution split the first-client work into its own plan because the
rollout order matters: Forgejo's SMTP mailer must be deployed and the
account e-mail changed *and activated* before any SSO behavior ships
(an SSO attempt whose IdP e-mail matches no Forgejo account would
otherwise auto-register a brand-new non-admin account instead of
linking into `britter`).

The staged runbook lives in
[`docs/plans/archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md`](2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md)
(Part A: SMTP mailer → account e-mail click-ops; Part B: the SSO
client). This archive ends after PR 3.

## Known effects

- **Certificate churn**: two new Let's Encrypt certs (one on srv-prod-1, one
  on directions), issued during the first nginx start after PR 1 switches.
  Cloudflare DNS-01, no propagation wait.
- **Transient SSO unavailability on deploys**: every srv-prod-1 switch
  restarts Keycloak (~15–30 s startup). Until clients exist this affects
  nothing; afterwards, login redirects fail briefly. Controlled by comin,
  not by this plan.
- **gatus flap at cutover**: the SSO check goes green only after both
  servers (directions entry + srv-prod-1 backend) have switched. Ordering
  between the two hosts is not guaranteed; a short flap is expected.
- **Admin accounts after section 1.5**: the temporary bootstrap admin is
  deleted, and PR 2 removes its (inert) environment wiring — it was only
  honored on the very first start and never a recovery path. The master
  realm holds one persistent human admin (password manager; may gain a
  second factor) and the `tofu` service-account client the provider
  authenticates with (client-credentials grant, per the provider docs'
  recommendation; its secret lives only in `secrets.json`, never in
  state). Users' passwords are never tofu-managed — see section 1.5.
  Rotating the provider secret: regenerate it in the console (Clients →
  tofu → Credentials) and `sops set` it into secrets.json. Break-glass:
  `kc.sh bootstrap-admin user` (tofu/keycloak README).
- **SMTP password in tofu state**: the realm's Brevo SMTP key is stored in
  the Keycloak realm and therefore in the tofu state in Garage. Accepted:
  the state bucket is readable only by the `tofu-keycloak` Garage key,
  held by exactly the hosts that can decrypt `secrets.json` (framework-13 +
  github-runners). Rotate by creating a new SMTP key in Brevo, `sops set`
  it into secrets.json, apply.
- **Forgejo-scoped effects** (client-secret lifecycle, auth-source
  rotation, the create-once auth source): moved with the Forgejo plan —
  see its Known effects section.

## Status

- [x] Repository exploration, provider/module verification
- [x] PR 1 files implemented
- [x] `nix flake check`, `nix fmt`, and host evaluations pass
- [x] PR 3 tofu code verified with `tofu validate` (scratch dir; caught
      `display_name` vs `realm_display_name`)
- [x] User: run step 1.1 (sops secrets) — host secrets added; secrets.json
      committed with PR 1 (the "left untracked" note was outdated), rotated
      in section 1.5
- [x] PR 1 merged; post-merge checks pass (IdP reachable, gatus green)
- [x] Section 1.5: persistent master-realm admin + `tofu` service-account
      client created, temporary `admin` deleted, secrets.json switched to
      client credentials (verified: token check `ok`)
- [x] Section 1.6: account-console 502 diagnosed — directions' nginx,
      "upstream sent too big header" on the account-console cookie bundle;
      fix folded into PR 2. Correction: the first fix (`proxy_buffer_size`
      alone) was invalid nginx config and took directions' nginx down at
      its next restart; replaced by the https-proxy module's
      `proxyHeaderBufferSize` option (see section 1.6)
- [x] PR 2 merged — step 2.1 secrets, proxy buffers raised, bootstrap env
      dropped, `sops unset` after the switch (commits `fd7769c`,
      `32032c9`, `08e7b65`). First restic snapshot not yet re-verified by
      hand (`ssh root@srv-prod-1 systemctl start restic-backups-keycloak`
      + status check, step 2.3)
- [x] PR 3 prepared (step 3.1 incl. SMTP credentials), merged, realm + bene
      user + SMTP applied; `bene`'s password was set through the
      forgot-password flow, which verified the SMTP path end to end
      (realm named `homelab` — see the header correction)
- ⇨ PR 4 (Forgejo onboarding) was split out mid-execution; its runbook
  and status live in docs/plans/archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md.
  This archive ends after PR 3 (PR 4b never became part of this plan).
