# Keycloak SSO on srv-prod-1, client config in tofu

**Status: PR 1 implemented and verified (`nix flake check`, `nix fmt`, and
host evaluations of srv-prod-1 + directions pass). PR 3's tofu code verified
with `tofu validate` (provider 5.10.0) in a scratch directory. PR 2 and PR 3
pending.**

## Chosen approach

Deploy Keycloak 26.8.1 (nixpkgs `services.keycloak`) on `srv-prod-1` behind the
per-host nginx (`services.https-proxy`), and manage the realm and all future
OIDC clients in a new tofu root `tofu/keycloak` using the official
`keycloak/keycloak` provider. The canonical frontend URL is
`https://account.ritter.family` (served by `directions`, targeting the per-host
vhost `https://account.srv-prod-1.ritter.family`, which targets Keycloak on
`127.0.0.1:8080`). The issuer URL is therefore decoupled from the host — if
Keycloak ever moves off srv-prod-1 (as the Beszel hub did), every client's
configured issuer keeps working.

Alternatives considered: Pocket ID was rejected because its only tofu
provider is a small community project covering OIDC clients only, which would
leave users/groups/passkeys hand-configured — a hard requirement against.
Authelia/Authentik were not considered; the requirement was Keycloak vs
Pocket ID.

## Why three PRs

Applies and switches both happen after merge: tofu pipelines apply on `main`,
and comin switches each server when `main` moves. That creates ordering
constraints that a single PR cannot guarantee:

1. **PR 1** deploys the IdP and creates the Garage buckets/keys that later
   phases consume. srv-prod-1's switch only needs the two new keycloak
   secrets, which are added to its `secrets.yaml` before the PR goes up.
2. **PR 2** adds the restic backup. It references the Garage key
   `restic-keycloak`, whose credentials only exist after PR 1's
   object-storage apply — and every sops secret referenced by the Nix config
   must exist in `secrets.yaml` before the switch, or activation fails and
   the host stays on its old generation.
3. **PR 3** adds the tofu root. Its pipeline `plan` needs a reachable
   Keycloak with the admin credentials from PR 1, and its `init` needs the
   `tofu-states-keycloak` bucket from PR 1's apply.

PR 2 and PR 3 are independent of each other and can go up in parallel after
PR 1 is verified.

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

Changed (PR 2):

- `modules/hosts/srv-prod-1/services/keycloak.nix` — restic backup of the
  Postgres dump
- `modules/hosts/srv-prod-1/secrets.yaml` — restic credentials (via `sops set`)

Changed (PR 3):

- `tofu/keycloak/` — new root (`provider.tf`, `main.tf`, `.envrc`,
  `README.md`, `secrets.json`)
- `.github/workflows/tofu-keycloak.yaml` — new pipeline
- `tofu/README.md` — root list

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
admin password and let Keycloak offer to delete the temporary admin
bootstrap warning (leave the user in place; tofu uses it). Check that gatus
shows the SSO endpoint green at `https://status.ritter.family`.

**Rollback (PR 1):** `git revert` the PR; comin switches back. The new
buckets/keys in Garage are inert and can stay. The Keycloak state
(Postgres data under `/var/lib/postgresql`) is disposable at this point —
no clients exist yet.

## PR 2 — backups

### 2.1 Prepare restic secrets (idempotent: no — run once, after PR 1's object-storage apply)

```bash
creds=$(tofu -chdir=tofu/object-storage output -json restic_user_credentials \
  | jq -r '.value.keycloak')

# jq without -r emits the value as a JSON string, which is exactly what
# sops set --value-stdin expects.
echo "$creds" | jq .access_key | sops set modules/hosts/srv-prod-1/secrets.yaml \
  '["restic"]["keycloak"]["garage-access-key-id"]' --value-stdin
echo "$creds" | jq .secret_key | sops set modules/hosts/srv-prod-1/secrets.yaml \
  '["restic"]["keycloak"]["garage-secret-access-key"]' --value-stdin
openssl rand -base64 24 | tr -d '/+=' | jq -R . | sops set modules/hosts/srv-prod-1/secrets.yaml \
  '["restic"]["keycloak"]["repository-password"]' --value-stdin
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

**Rollback (PR 2):** revert; comin switches back. The restic repo in Garage
stays (harmless, will be pruned by retention once unused).

## PR 3 — tofu root for realm/client management

### 3.1 Finish secrets.json (idempotent: yes — `sops set` overwrites each key)

```bash
creds=$(tofu -chdir=tofu/object-storage output -json managed_state_user_credentials \
  | jq -r '.value.keycloak')

echo "$creds" | jq .access_key | sops set tofu/keycloak/secrets.json \
  '["state_bucket_key_id"]' --value-stdin
echo "$creds" | jq .secret_key | sops set tofu/keycloak/secrets.json \
  '["state_bucket_secret_key"]' --value-stdin
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
provider "keycloak" {
  client_id = "admin-cli"
  url       = data.sops_file.secrets.data["keycloak_url"]
  username  = data.sops_file.secrets.data["keycloak_admin_username"]
  password  = data.sops_file.secrets.data["keycloak_admin_password"]
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
  registration_allowed   = false
  reset_password_allowed = false
  verify_email           = false

  ssl_required = "external"
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

Short root README: what it manages (realm `ritter`, later one
`keycloak_oidc_client` resource per service), where the admin credentials
come from (`secrets.json`, same value as srv-prod-1's
`keycloak/admin-password`), the `.envrc` flow, and the note that the realm
is created by tofu — if it is ever created manually first, run
`tofu import keycloak_realm.ritter ritter`.

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
tofu plan          # expected: + keycloak_realm.ritter
```

The PR's pipeline plan comment must show the same single resource. Merge;
the pipeline applies on `main`.

### 3.4 Post-merge check

```bash
curl -s https://account.ritter.family/realms/ritter/.well-known/openid-configuration | jq -r .issuer
# expected: https://account.ritter.family/realms/ritter
```

**Rollback (PR 3):** revert; comin is unaffected. The pipeline apply is
state-based: a revert deletes the realm on the next apply. Only do that when
no clients are enrolled yet — deleting the realm invalidates every issuer
URL that points into it.

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
- **Admin bootstrap password persists in the environment**: the sops
  template is injected on every start. Keycloak ignores it once the `admin`
  user exists (documented recovery path). Rotating
  `keycloak/admin-password` in the sops file and restarting the service
  rotates it for both recovery and tofu (keep `tofu/keycloak/secrets.json`
  in sync).

## Status

- [x] Repository exploration, provider/module verification
- [x] PR 1 files implemented
- [x] `nix flake check`, `nix fmt`, and host evaluations pass
- [x] PR 3 tofu code verified with `tofu validate` (scratch dir; caught
      `display_name` vs `realm_display_name`)
- [x] User: run step 1.1 (sops secrets) — host secrets added; secrets.json
      created and left untracked for PR 3
- [ ] PR 1 opened, pipeline plan checked, merged, post-merge checks pass
- [ ] PR 2 prepared (step 2.1), merged, first backup verified
- [ ] PR 3 prepared (step 3.1), merged, realm applied and verified
