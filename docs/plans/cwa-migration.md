# Plan: Replace calibre-web with Calibre-Web-NextGen on srv-prod-5

**Status:** ⏳ Draft — not started
**Created:** 2026-11-02

## Goal

Replace the plain `calibre-web` service on srv-prod-2 with
**Calibre-Web-NextGen (CWNG)** — the actively maintained community
continuation of Calibre-Web-Automated (CWA) — plus a **self-hosted KOSync
server** and a **CWA sync bridge**, running the stack on **srv-prod-5**
instead. Everything is implemented as native NixOS config — no Docker
containers.

The stack follows the architecture from
[youtube.com/watch?v=zljqMj_pRjY](https://youtu.be/zljqMj_pRjY) (CWA + a
separate KOSync server + a bridge between them). The video deploys all three
as Docker containers; here every component becomes a Nix package plus a
systemd service.

## Chosen approach

Three new native components on srv-prod-5:

```
KOReader devices ──> kosync.ritter.family ──> kosync server (self-hosted)
                                                  │ poll
                                                  ▼
                                          kosync-cwa-bridge
                                                  │ PUT /kosync/syncs/progress
                                                  ▼
Kobo devices ──────────────────────────────> books.ritter.family ──> CWNG
Browsers / OPDS ───────────────────────────>      (port 8083, localhost)
```

- **CWNG** — community continuation of CWA: automated ingest, format
  conversion (kepubify), metadata enforcement, Kobo sync, and a `/kosync`
  endpoint. Drop-in data-format compatible with CWA. Replaces
  `services.calibre-web` 1:1 at the same URL (`books.ritter.family`).
- **KOSync server** — a self-hosted implementation of the KOReader progress
  sync protocol. KOReader devices point their **stock** *Progress sync*
  plugin at it.
- **Bridge** (`kosync-cwa-bridge`) — small Python sidecar. It polls the
  KOSync server for each checksum in `metadata.db` and pushes new progress
  into CWNG through its `/kosync` endpoint (works with CWA and CWNG alike).
  This makes progress visible in the web UI and propagates it to Kobo sync
  and Hardcover integrations.

### Base choice: CWNG over upstream CWA

CWNG ([new-usemame/Calibre-Web-NextGen](https://github.com/new-usemame/Calibre-Web-NextGen))
is a community continuation of CWA that ships fixes and CWA's queued PRs in
frequent releases (~190 releases May–Oct 2026; CWA itself was at v4.0.8 in
Oct 2026). It is data-format and configuration identical to CWA — upstream
documents switching as a one-line image change and reversing it the same
way — so choosing it carries no lock-in. Decisive for this plan:

- CWNG **documents runtime path overrides for non-Docker packaging**
  (`docs/runtime-paths.md`: `CWA_INGEST_FOLDER`, `CWA_CALIBRE_LIBRARY_DIR`,
  `CWA_TMP_CONVERSION_DIR`, `CWA_DIRS_JSON`) — the upstream CWA Nix
  packaging PR had to patch out dozens of hardcoded Docker paths instead.
- The bridge and the KOSync architecture are fork-agnostic.

### SSO capability: native OIDC in CWNG

CWNG ships an environment-managed Generic OIDC provider
(`docs/OAUTH-ENVIRONMENT-CONFIGURATION.md` upstream; checked against
the README 2026-11-12 — re-verify against the pinned CWNG tag at
implementation time, upstream reviews auth code more closely). Built
for declarative deployments: OIDC discovery URL, client secret from a
file (`GENERIC_OAUTH_CLIENT_SECRET_FILE`, sops-rendered — nothing
lands in `app.db`), claim mappers (`preferred_username`, `email`),
group-claim admin mapping (`GENERIC_OAUTH_ADMIN_GROUP`, requires the
global "Manage admin role from OAuth group" switch), an in-app group
allow-list, and a default role for auto-created users
(`GENERIC_OAUTH_DEFAULT_ROLE`, e.g. `download,viewer` — `admin` is
deliberately not a valid token).

This supersedes the rollout plan's "No — auth proxy" marking: the web
UI becomes a native Keycloak client once this migration lands — the
SSO rollout for calibre-web is blocked by this migration. With the
realm's `admins` group (see the role-mapping decision in
`keycloak-sso-rollout.md`): `bene` is CWNG admin on login, every other
user auto-creates as a normal reader.

Device surfaces cannot follow a browser OIDC redirect and keep local
credentials permanently: `/opds` (KOReader basic-auth credentials
embedded in the URL), Kobo sync tokens, `/kosync` (bridge), and the
KOSync vhost. Local user accounts with passwords therefore stay —
every reader needs one for their devices — and the standard login form
stays enabled (the OIDC doc describes no switch to disable it; OPDS
shares the same credential store anyway). PKCE is undocumented: probe
the authorization endpoint at onboarding and only enforce S256 on the
Keycloak client if the probe shows the challenge arrives.

### Why a separate KOSync server (not CWNG's built-in sync)?

Both CWA ≥ 4.0 and CWNG ship a built-in `/kosync` endpoint. Two reasons to
still run the separate server, matching the video's architecture:

1. **Client compatibility.** CWA's `/kosync` authenticates with HTTP Basic
   auth, while every standard KOReader client sends the classic
   `x-auth-user`/`x-auth-key` (MD5) headers — stock clients cannot
   authenticate against it
   ([bookbridge issue #334](https://github.com/cporcellijr/bookbridge/issues/334)).
   The bridge can use Basic auth; standard devices cannot.
2. **No per-device plugin installs.** CWNG's built-in sync works with its
   own `cwngsync.koplugin`, which must be installed and updated on every
   reader. A self-hosted KOSync server works with the plugin that ships in
   every KOReader install, unchanged.

The split also decouples device sync from web-app releases: a CWNG upgrade
cannot take e-reader progress sync down with it.

### Packaging decisions (all verified against nixpkgs on this host)

| Component | nixpkgs? | Decision |
| --- | --- | --- |
| `calibre-web-nextgen` | ❌ not packaged (verified: `nix search nixpkgs calibre` → only `calibre`, `calibre-no-speech`, `calibre-web`; nothing for CWNG either) | Start from [crocodilestick/Calibre-Web-Automated PR #1416 "Add Nix Packaging"](https://github.com/crocodilestick/Calibre-Web-Automated/pull/1416) — a PR on the **CWA repository** (open as of 2026-11, not merged, **not** a nixpkgs PR) — and retarget it at CWNG. It contains a `nix/package.nix`, `nix/patch_paths.py`, and a `nix/module.nix`. Since CWNG is CWA-based, the packaging transfers, but replace the Docker-path seds with CWNG's documented env-var overrides (`CWA_INGEST_FOLDER`, `CWA_CALIBRE_LIBRARY_DIR`, `CWA_TMP_CONVERSION_DIR`, `CWA_DIRS_JSON`) wherever they cover a patched path. Pin the source to a CWNG release tag (v4.1.60 at plan time). |
| KOSync server | ❌ not packaged (verified: `nix search nixpkgs kosync` → no results) | Package **[mgdelacroix/kosync](https://git.ctrlz.es/mgdelacroix/kosync)** (Go, single binary, SQLite/WAL, registration flag, `buildGoModule`-friendly). Alternatives: `fellipec/kosync-go` (JSON file store — weaker durability), `kosync-rs` (Rust/SQLite), `AtjonTV/kosync` (Go + PocketBase, WebUI/OPDS — heavier than needed). |
| `kosync-cwa-bridge` | ❌ not packaged | Package [ericchansen/kosync-cwa-bridge](https://github.com/ericchansen/kosync-cwa-bridge) as a `buildPythonApplication` (has `pyproject.toml`, `src/` layout). Runs as a systemd service with a sops-rendered `config.yml`. Its README states it works with CWA and CWNG alike. |

**Alternatives considered, rejected:**

- *Stay on plain calibre-web and add only KOSync + bridge*: calibre-web
  upstream (0.6.27) has no `/kosync` endpoint, so the bridge has nothing to
  push into. The bridge requires CWA or CWNG.
- *Use the built-in KOReader sync and skip the separate server*: works only
  with each fork's own plugin on every device (CWNG) or not at all with
  stock clients (CWA — auth mismatch, see above). The separate server keeps
  stock KOReader installs working unmodified.
- *Base on upstream CWA instead of CWNG*: same data format, but slower
  release cadence and no packaging docs; CWNG is its community continuation
  and drop-in compatible in both directions.
- *Run upstream Docker images via podman*: srv-prod-5 has no container
  stack today; the repo's convention is declarative NixOS services, and all
  three components package cleanly.

## Places that change vs. places that stay

### Changes

| Place | Change |
| --- | --- |
| `packages/calibre-web-nextgen/` | new package (from CWA PR #1416, retargeted at CWNG) |
| `packages/kosync/` | new package (mgdelacroix/kosync) |
| `packages/kosync-cwa-bridge/` | new package |
| `modules/nixos/calibre-web-nextgen.nix` | new base aspect, upstreamable module style (`services.calibre-web-nextgen.*`) |
| `modules/nixos/kosync.nix` | new base aspect (`services.kosync.*`) |
| `modules/nixos/kosync-cwa-bridge.nix` | new base aspect (`services.kosync-cwa-bridge.*`) |
| `modules/hosts/srv-prod-5/services/calibre-web-nextgen.nix` | new instance `calibre-web-nextgen-on-srv-prod-5` (paths, secrets, proxy registration, restic backup) |
| `modules/hosts/srv-prod-5/configuration.nix` | import the new instance |
| `modules/hosts/srv-prod-5/secrets.yaml` | restic + bridge secrets (srv-prod-5 age key already in `.sops.yaml`) |
| `modules/hosts/srv-prod-2/configuration.nix` | drop `calibre-web-on-srv-prod-2` import |
| `modules/hosts/srv-prod-2/services/calibre-web.nix` | delete (instance incl. its restic backup) |
| `modules/nixos/calibre-web.nix` | delete (generic aspect, no longer used anywhere) |
| `modules/hosts/directions/services/https-proxy.nix` | repoint `books.ritter.family` → `https://books.srv-prod-5.ritter.family`; add `kosync.ritter.family` vhost |
| `modules/nixos/gatus.nix` | keep Calibre-Web check; add KOSync `healthcheck` check |
| `tofu/proxmox/srv-prod-5.tf` | bump memory (2 GB → 4 GB) and cores (2 → 4) for CWNG + calibre conversion load |
| `docs/homelab.md` | service table row moves to srv-prod-5, gains KOSync |
| `docs/plans/keycloak-sso-rollout.md` | Calibre Web row: app name becomes CWNG; SSO classification flips from auth-proxy to native OIDC (see "SSO capability" above) — the SSO rollout for this service is blocked until this migration lands; the `/opds` exemption note carries over, joined by the Kobo/`/kosync` surfaces |

### No changes (each with reason)

| Place | Reason |
| --- | --- |
| Cloudflare DNS (`tofu/dns/`) | Both `*.ritter.family` (directions wildcard) and per-server wildcards already exist; `books.srv-prod-5.ritter.family` and `kosync.srv-prod-5.ritter.family` resolve automatically once nginx answers on srv-prod-5. |
| `modules/nixos/homepage.nix` | Links to `https://books.ritter.family` — the public URL does not move. |
| `tofu/dns/tailscale/` | Tailscale records are per-host, not per-service. |
| srv-prod-2 NFS/storage | The calibre library is plain local disk (`/var/lib/calibre-library`); nothing to unmount, only copy out. |
| Navidrome on srv-prod-5 | Independent; shares only the VM. |

## Runbook

> **Rollout mechanics:** comin pulls from the repo URL and switches a server
> as soon as `main` moves. Every merge below is followed by
> `systemctl list jobs` / service check on the affected host **before** the
> next merge. Phases are separated by merge boundaries on purpose — do not
> batch them.
>
> **Verification status:** commands marked ⚠️ have not been executed yet;
> they were derived from file contents and the upstream PR. Run them when
> reaching the step and record deviations here.

---

### Phase 0 — Prep (no repo change)

1. ⚠️ Measure the library on srv-prod-2:
   ```
   ssh root@books.srv-prod-2.ritter.family 'du -sh /var/lib/calibre-library /var/lib/calibre-web'
   ```
   Record result here: ____________. If the library exceeds ~35 G, expand
   the srv-prod-5 disk first (`tofu/proxmox/DISK-RESIZE-PLAYBOOK.md`).
2. ⚠️ Confirm srv-prod-5 headroom:
   ```
   ssh root@srv-prod-5.ritter.family 'df -h /; free -h'
   ```

**Check:** numbers recorded. Disk on srv-prod-5 must fit library + 20 %
headroom (conversion temp files land in `/var/lib/calibre-web-nextgen/tmp`).

**Rollback:** none needed.

---

### Phase 1 — VM resources (tofu, gitops)

1. PR editing `tofu/proxmox/srv-prod-5.tf`: `cores = 4`, `memory = 4096`.
2. The tofu pipeline plans on the PR and applies after merge to `main`
   (never apply locally). Memory may require a VM stop/start to fully apply —
   do it in the maintenance window of Phase 3 if it doesn't hot-apply.

**Check (idempotent, safe to re-run):** ⚠️
```
ssh root@srv-prod-5.ritter.family 'nproc; free -h | grep Mem'
```

**Rollback:** revert the tf file; reapply via pipeline.

---

### Phase 2 — Packages and base aspects (safe merge)

1. Vendor CWA packaging from [Calibre-Web-Automated PR #1416](https://github.com/crocodilestick/Calibre-Web-Automated/pull/1416)
   (the CWA repo's own Nix-packaging PR, not nixpkgs) and retarget it at
   CWNG:
   - `packages/calibre-web-nextgen/default.nix` — based on the PR's
     `nix/package.nix` plus `patch_paths.py`; source via `fetchFromGitHub`
     pinned to a CWNG release tag (v4.1.60 at plan time), not `../.`.
     Drop every Docker-path sed that CWNG's documented env overrides make
     redundant (`CWA_INGEST_FOLDER`, `CWA_CALIBRE_LIBRARY_DIR`,
     `CWA_TMP_CONVERSION_DIR`, `CWA_DIRS_JSON`); keep the flask-limiter and
     setuptools fixes, which are version-dependent — re-check each against
     the pinned CWNG tag.
   - `modules/nixos/calibre-web-nextgen.nix` — based on the PR's
     `nix/module.nix`, wrapped as
     `flake.modules.nixos.calibre-web-nextgen = { ... }` in the
     conventional module style the PR already uses (`mkEnableOption`,
     `mkPackageOption`, disabled by default). Keep its `libraryDir` /
     `ingestDir` / `environment` options; set the env overrides from them.
2. `packages/kosync/default.nix` — `buildGoModule` for mgdelacroix/kosync;
   `modules/nixos/kosync.nix` — module with `services.kosync.{enable,package,
   port,registration}` writing state to `/var/lib/kosync`.
3. `packages/kosync-cwa-bridge/default.nix` — `buildPythonApplication`;
   `modules/nixos/kosync-cwa-bridge.nix` — module with
   `services.kosync-cwa-bridge.{enable,package,settings}` where `settings`
   renders `config.yml` (bridging `kosync_roks.url`, `cwa.url`,
   `metadata_db_path`, `poll_interval_seconds`); secrets stay outside via
   `sops.templates` at the instance layer.
4. Nothing enables these aspects yet — this merge only makes the options
   exist.

**Check:** ⚠️
```
nix build .#packages.x86_64-linux.calibre-web-nextgen .#packages.x86_64-linux.kosync .#packages.x86_64-linux.kosync-cwa-bridge
nix flake check
```
Then merge. comin will switch all servers; eval-only changes for every host
(no service differences). Expect a no-op switch.

**Rollback:** `git revert` the merge; comin redeploys. No state was touched.

---

### Phase 3 — Stand up the stack on srv-prod-5 (library still empty)

Create `modules/hosts/srv-prod-5/services/calibre-web-nextgen.nix`
defining `calibre-web-nextgen-on-srv-prod-5`:

@@ modules/hosts/srv-prod-5/services/calibre-web-nextgen.nix @@
```nix
{ config, ... }:
{
  flake.modules.nixos.calibre-web-nextgen-on-srv-prod-5 =
    { config, ... }:
    {
      imports = with config.flake.modules.nixos; [
        calibre-web-nextgen
        kosync
        kosync-cwa-bridge
      ];

      services.calibre-web-nextgen = {
        enable = true;
        libraryDir = "/var/lib/calibre-library";
        ingestDir = "/var/lib/cwa-book-ingest";
        environment = {
          TRUSTED_PROXY_COUNT = "2"; # directions edge proxy + local https-proxy
        };
      };

      services.kosync = {
        enable = true;
        registration = false; # flip to true once, register, then back to false
      };

      services.kosync-cwa-bridge = {
        enable = true;
        settings = {
          kosync_roks.url = "http://localhost:${toString config.services.kosync.port}";
          cwa.url = "http://localhost:8083";
          metadata_db_path = "/var/lib/calibre-library/metadata.db";
          poll_interval_seconds = 300;
        };
      };

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "books.${config.networking.hostName}.ritter.family";
            aliases = [ "books.ritter.family" ];
            target = "http://localhost:8083";
            maxBodySize = "100M";
            # Kobo sync responses carry large headers; nginx's 4k default
            # silently 502s them ("upstream sent too big header")
            proxyHeaderBufferSize = "32k";
          }
          {
            fqdn = "kosync.${config.networking.hostName}.ritter.family";
            aliases = [ "kosync.ritter.family" ];
            target = "http://localhost:${toString config.services.kosync.port}";
          }
        ];
      };

      services.restic.backups.calibre = {
        # same shape as the old srv-prod-2 instance; secrets move to this
        # host's secrets.yaml (see below)
        paths = [
          "/var/lib/calibre-web-nextgen"
          "/var/lib/calibre-library"
        ];
        repository = "s3:https://garage.srv-prod-3.ritter.family/restic-calibre";
        initialize = true;
        pruneOpts = [ ... ];
        timerConfig = { ... };
      };
    };
}
```

Placeholder note: `pruneOpts`/`timerConfig` copy
`modules/hosts/srv-prod-2/services/_restic-constants.nix` values; the restic
secret values are **not** copyable from this plan — move them with sops.

Steps:

1. Add secrets to `modules/hosts/srv-prod-5/secrets.yaml` (srv-prod-5's age
   key is already in `.sops.yaml`):
   - `restic/calibre/repository-password`,
     `restic/calibre/garage-access-key-id`,
     `restic/calibre/garage-secret-access-key` — pipe the plaintext values
     out of srv-prod-2's secrets.yaml via `sops -d ... | sops --set ...`;
     never through a clipboard.
   - `calibre/bridge/cwa-password` and `calibre/bridge/kosync-password` —
     new values; the bridge's `config.yml` is rendered with
     `sops.templates` using placeholders.
2. Import `calibre-web-nextgen-on-srv-prod-5` in
   `modules/hosts/srv-prod-5/configuration.nix`. Merge.
3. ⚠️ After comin switches srv-prod-5, verify locally:
   ```
   curl -s http://localhost:8083 | grep -i calibre   # CWNG up
   curl -s http://localhost:8083/healthcheck         # kosync healthcheck
   systemctl status kosync-cwa-bridge
   ```
4. Manual (browser, via `books.srv-prod-5.ritter.family`, internal DNS):
   - Log in as default `admin` / `admin123`, change the password, create the
     normal user account(s) — **users are not carried over** from the old
     calibre-web (different app database).
   - Basic config per the video: enable uploads, enable Kobo sync,
     external port 443, **disable "embed metadata to ebook file"** (it
     breaks Kobo cover pushes), CWNG settings: enable automatic metadata
     fetching, auto-convert target format `kepub`.
   - Enable CWNG's KOReader sync (the `/kosync` endpoint) so it accepts the
     bridge's pushes.
   - Register the KOSync user while `services.kosync.registration` is
     temporarily enabled (one extra merge or `--registration` flag flip),
     then disable registration again.
   - Drop one test EPUB into `/var/lib/cwa-book-ingest`; watch it convert
     and appear in the library. ⚠️
   - Push a fake progress entry through the kosync server with curl
     (`PUT /syncs/progress`, `x-auth-user`/`x-auth-key`) and confirm the
     bridge moves it into CWNG within one poll interval. ⚠️
5. Enable the restic backup once by hand (`systemctl start
   restic-backups-calibre`) and confirm a snapshot lands in garage. ⚠️

**Check:** CWNG UI reachable at `https://books.srv-prod-5.ritter.family`
(internal), empty library listed, ingest + bridge round-trip proven, first
backup snapshot present. Old calibre-web on srv-prod-2 still serving
`books.ritter.family` during this whole phase.

**Rollback:** remove the import; comin switches srv-prod-5 back; delete
`/var/lib/calibre-library` on srv-prod-5 (not idempotent — deleting twice
is a no-op, deleting at all destroys the fresh CWNG state only; the real
library on srv-prod-2 is untouched so far).

---

### Phase 4 — Cutover (downtime window)

Order is fixed: stop old first, move data, then switch URLs.

1. **Merge: remove `calibre-web-on-srv-prod-2`** from
   `modules/hosts/srv-prod-2/configuration.nix` (do **not** yet delete the
   generic `modules/nixos/calibre-web.nix` — the old instance file
   disappears in the same merge). comin stops and disables
   `calibre-web.service` and `restic-backups-calibre.service` on srv-prod-2.
   ⚠️ Check after switch:
   ```
   ssh root@srv-prod-2.ritter.family 'systemctl is-active calibre-web || echo stopped'
   ```
   `books.ritter.family` is now down. This is the start of the downtime
   window.
2. **Move data.** Do a final incremental rsync (an earlier online pre-copy
   between Phase 3 and this merge shrinks this step):
   ```
   # not idempotent in effect: overwrites any newer CWNG-side state
   rsync -aHAX --delete root@srv-prod-2.ritter.family:/var/lib/calibre-library/ \
                         root@srv-prod-5.ritter.family:/var/lib/calibre-library/
   ```
   ⚠️ Then stop CWNG on srv-prod-5 during the copy is unnecessary if the
   library is still empty there; if Phase 3 ingested test books, delete
   `/var/lib/calibre-library/*` on srv-prod-5 first, copy, then
   `systemctl restart calibre-web-nextgen kosync-cwa-bridge`.
3. **Merge: switch directions.** In
   `modules/hosts/directions/services/https-proxy.nix`:
   @@ modules/hosts/directions/services/https-proxy.nix @@
   ```diff
         {
           fqdn = "books.ritter.family";
   -       target = "https://books.srv-prod-2.ritter.family";
   +       target = "https://books.srv-prod-5.ritter.family";
           maxBodySize = "512M";
         }
   ```
   Add the KOSync vhost in the same merge:
   ```diff
   +      {
   +        fqdn = "kosync.ritter.family";
   +        target = "https://kosync.srv-prod-5.ritter.family";
   +      }
   ```
4. ⚠️ End-of-window checks:
   - `curl -s https://books.ritter.family` → 200 (via Gatus within 5 min)
   - OPDS basic auth still works: load
     `https://books.ritter.family/opds` in KOReader with embedded
     credentials — must **not** be broken by any future auth-proxy work
     (note lives in `docs/plans/keycloak-sso-rollout.md`).
   - Kobo sync: trigger a sync on the Kobo; it talks to CWNG through
     `books.ritter.family` — should work unchanged.
   - KOReader devices: set *Progress sync → custom sync server* to
     `https://kosync.ritter.family` with the registered credentials
     (one-time per-device step).

**Rollback (phase 4):** re-point directions to
`https://books.srv-prod-2.ritter.family` (one-merge revert of step 3) and
re-add the `calibre-web-on-srv-prod-2` import (revert of step 1). Both hosts
still hold their state: srv-prod-2's library was rsync'd, not moved. The
rollback ends with deleting `/var/lib/calibre-library` on srv-prod-5 — that
delete is the step that ends state-based rollback.

---

### Phase 5 — Cleanup (after the rollback window, e.g. one week)

1. Delete `modules/nixos/calibre-web.nix` and
   `modules/hosts/srv-prod-2/services/calibre-web.nix` (the restic backup
   config dies with it; the garage bucket keeps existing snapshots).
2. Remove the now-unused `restic/calibre/*` keys from
   `modules/hosts/srv-prod-2/secrets.yaml`.
3. Update `docs/homelab.md` (books → srv-prod-5, add kosync row) and the
   Calibre Web row in `docs/plans/keycloak-sso-rollout.md` (now
   CWNG with native OIDC; OPDS + device-API note stays).
4. Gatus: confirm the existing Calibre-Web check is green; add a KOSync
   check on `https://kosync.ritter.family/healthcheck` in the same PR.

**Check:** `nix flake check` clean; no reference to `calibre-web` left
except the NextGen aspect (`rg -n "calibre-web[^-]" modules/`). ⚠️

**Rollback:** not applicable — this phase only removes dead config; Phase 4
rollback still works until these files are gone.

## Known effects

- **Downtime window** for `books.ritter.family` between the Phase 4
  merge 1 and merge 3. Length ≈ rsync time + two comin switches. Controlled
  by Phase 4 steps 1–3. Reduce by pre-copying online before the window.
- **User accounts are reset** — CWNG keeps its own `app.db`; old
  calibre-web users do not carry over. Recreated by hand in Phase 3 step 4.
- **Metadata churn on first CWNG start** — CWNG may enforce metadata/covers
  and generate checksums (`book_format_checksums`) across the migrated
  library. The pre-migration state stays recoverable via the last
  srv-prod-2 restic snapshot in the `restic-calibre` garage bucket.
- **KOReader devices need a one-time config change** (custom sync server →
  `kosync.ritter.family`). Until then, device→device progress sync for
  KOReader is unavailable; OPDS downloads work as before.
- **Reading progress lands in CWNG with up to a 5-minute lag** (bridge poll
  interval), and the flow is one-way: kosync → CWNG. Marking a book "Read"
  in CWNG does not push back to KOSync.
- **Registration on the KOSync server is off by default**; a deliberate
  temporary enable/disable cycle is needed per new user.
- **Certificate churn** — none: `books.ritter.family` terminates on the
  directions nginx against wildcard certs; backend certs on srv-prod-5 are
  issued by the same `https-proxy` mechanism used by every other service.
