# Plan: Manage Home Assistant's configuration.yaml in git

Status: **rejected 2026-11-03** — after correcting the scope (HA 2026.8
removed the proxy-trust config from YAML entirely), the remaining
`configuration.yaml` turns out to be a few default includes only. That
is not worth the mirror/add-on machinery. The guardrails documented in
`docs/incidents/2026-11-02-home-assistant-unreachable.md` (tofu comment
+ gatus check) are the final state. Only remaining action: remove the
dead `http:` block from the device's `configuration.yaml`.

The analysis is kept as reference — in particular the Git pull add-on's
storage semantics (tracked vs. untracked files in `/config`) and the
2026.8 migration traps (one-time YAML import, 5-minute confirm dialog).

> **Scope correction (2026-11-03):** Home Assistant 2026.8 moved the
> entire `http:` block (including `trusted_proxies` and
> `use_x_forwarded_for`) out of `configuration.yaml` into UI storage
> (`/config/.storage/http`), imported once and never read from YAML
> again (hard removal in 2027.2.0). The proxy-trust config that
> motivated this plan **cannot** live in git at all — it is
> UI-managed, permanently. This plan now covers versioning *the rest*
> of `configuration.yaml`; the proxy-trust dependency keeps its
> guardrails (tofu comment + gatus check + the UI path documented in
> the tofu comment). See the incident doc for the full story.

## Context

Home Assistant runs on a dedicated HAOS device (192.168.20.234:8123,
UniFi client `homeassistant`, not a NixOS host). Its `configuration.yaml`
was click-ops. That contributed to the 2026-11-02 outage: the VLAN
migration of `directions` (PR #70, `192.168.5.6` → `192.168.30.6`) left
HA's proxy-trust setting pointing at the old IP — a setting that, since
HA 2026.8, lives in UI storage and had imported the stale pre-migration
YAML value. HA rejected every proxied request with 400. See
`docs/incidents/2026-11-02-home-assistant-unreachable.md`.

Scope decision: **only `configuration.yaml` is managed declaratively.**
Devices, areas, dashboards etc. stay UI-managed (they live in
`.storage/`, which stays out of git). HAOS has no sops, so
`secrets.yaml` also stays untracked on the device.

## Alternatives considered

| Option | Verdict |
|---|---|
| Click-ops + guardrails (tofu comment + gatus) | In place; remains as safety net — and is the *only* option for the proxy-trust setting itself |
| Terraform provider `toelke/homeassistant` | Cannot manage `configuration.yaml` (no HA API for that file) — only registries/automations/config entries |
| Orphan branch `ha-config` in this repo | Works (repo is only ~25 MB of git), but config lives on a divergent second root; poor discoverability |
| Dedicated repo, manual push | Second source of truth, easy to forget |
| **GH Actions subtree mirror (chosen)** | Config on `main` next to tofu/nix config; device repo is a build artifact; small, loud failure mode |
| NixOS `services.home-assistant` module | Clean end state, but a migration project (USB radios, add-ons, registries) — out of scope |

## Target architecture

```
nix-configuration (main)                     ha-config (private repo, root)
├─ home-assistant/
│  ├─ configuration.yaml   ──(subtree split)►├─ configuration.yaml
│  └─ README.md            ──────────────►   └─ README.md
├─ .github/workflows/ha-config-sync.yml          ▲
├─ tofu/network/clients.tf (points here)         │ git pull (read-only
└─ docs/incidents/…        (points here)         │ deploy key, every 5 min,
                                                 │ restart on change)
                                                 │
                                          HA device /config
                                          (+ untracked: secrets.yaml,
                                           .storage/, DB)
```

- **Monorepo `main` is the single source of truth.** PRs touch
  `home-assistant/configuration.yaml` like any other file.
- The workflow runs `git subtree split --prefix=home-assistant` and pushes
  the result (root = `configuration.yaml`) to `britter/ha-config` `main`.
- The official **Git pull** add-on (`core_git_pull`, `home-assistant/addons`)
  on the HA device pulls that repo into `/config`, validates the config,
  and restarts HA when tracked files change.
- Auth: read-only SSH **deploy key** on `ha-config` for the device (device
  can never push). Workflow pushes use a fine-grained PAT
  (`HA_CONFIG_TOKEN`, contents:write on `ha-config` only) stored as an
  Actions secret.

## Implementation steps

1. **Create `britter/ha-config`** (private, empty, branch `main`).
   - Add read-only deploy key (`gh repo deploy-key add -- --title "ha device (read-only)"`).
   - Create fine-grained PAT, store as Actions secret `HA_CONFIG_TOKEN` in nix-configuration.
2. **Seed the device repo with the live config** (behavior-neutral
   first pull):
   - Export `configuration.yaml` from the HA device (SSH/Samba/File
     editor; needs manual step — paste from device).
   - Before committing, **remove the `http:` block** — it has been dead
     since HA 2026.8's migration and is pure noise (see scope
     correction above). The first pull therefore applies exactly one
     change: deleting the ignored block. Behavior-neutral, clears the
     repair issue.
   - Commit to `ha-config` `main`, plus a README describing the pipeline,
     that `secrets.yaml` is device-local, and that the proxy-trust
     setting lives in the UI (Settings > System > Network), not in this
     repo.
3. **Install and configure the Git pull add-on** on the HA device:
   ```yaml
   repository: git@github.com:britter/ha-config.git
   git_branch: main
   git_command: reset      # reset --hard each poll; overwrites tracked
                           # files ONLY — untracked files survive
   auto_restart: true      # validates config before restarting
   restart_ignore: [".gitignore", "README.md"]
   repeat: { active: true, interval: 300 }
   deployment_key: <private key of the read-only deploy key>
   deployment_key_protocol: ed25519
   ```
   - Take a full HA backup first; the add-on backs up `/config` on the
     initial clone anyway.
   - **The first start is the destructive moment:** the add-on clones the
     repo into `/config`, replacing its content (the script attempts to
     restore non-YAML files and secrets, but the official docs warn of
     complete loss). After the first start, before anything else, verify
     against the backup that `.storage/`, `secrets.yaml`,
     `home-assistant_v2.db`, `automations.yaml` and `blueprints/` are
     intact.
   - Verify: add-on log shows a clean pull with **no changes applied**
     (device state and repo seed are identical).
4. **Merge the monorepo side** (single PR):
   - `home-assistant/configuration.yaml` — mirror of the seeded content.
   - `home-assistant/README.md` — the pipeline diagram above, the
     `secrets.yaml` note, and "UI edits to configuration.yaml are
     overwritten within ~5 min" warning, plus the one-tracked-file rule
     (never track UI-owned files like `automations.yaml` — see the
     `/config` inventory under "Semantics after rollout").
   - `.github/workflows/ha-config-sync.yml` — see
     [The sync workflow](#the-sync-workflow) below.
   - Reword the comment on `unifi_client.directions` in
     `tofu/network/clients.tf`: point at
     `home-assistant/configuration.yaml` in this repo (dependency is now
     greppable from the networking side).
   - Update the follow-ups in
     `docs/incidents/2026-11-02-home-assistant-unreachable.md`:
     mark the "manage configuration.yaml from this repo" item done,
     link to this plan.
5. **End-to-end test:** PR that changes a harmless key in
   `home-assistant/configuration.yaml` → merge → watch the workflow →
   verify the add-on pulls and restarts within ~5 min → gatus stays green
   through the restart window.

## The sync workflow

`.github/workflows/ha-config-sync.yml`:

```yaml
name: ha-config-sync

on:
  push:
    branches: [main]
    paths: ["home-assistant/**"]

concurrency:
  group: ha-config-sync
  cancel-in-progress: false

permissions:
  contents: read

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0   # subtree split walks history; shallow clone breaks it

      - name: Split home-assistant/ to repo root
        run: git subtree split --prefix=home-assistant -b split

      - name: Push to ha-config
        run: |
          git push --force \
            "https://x-access-token:${HA_CONFIG_TOKEN}@github.com/britter/ha-config.git" \
            split:main
        env:
          HA_CONFIG_TOKEN: ${{ secrets.HA_CONFIG_TOKEN }}
```

Behavior and rationale:

- **Trigger:** push to `main` touching `home-assistant/**`. Merges that
  don't touch HA config don't run it; the tofu comment reword and incident
  doc live outside the path filter and won't cause syncs.
- **`git subtree split --prefix=home-assistant`** rewrites history so each
  commit's tree contains only `home-assistant/` content at the root. The
  device repo therefore has `configuration.yaml` at root — the layout the
  Git pull add-on requires — while the monorepo keeps its normal
  directory structure. The split is deterministic: unchanged input history
  produces unchanged split commits, so most runs push a no-op.
- **`--force` push is safe and intentional.** The device side is
  configured with `git_command: reset` (hard reset to `origin/main` every
  poll), so rewritten history never conflicts on the device. Force is also
  what makes the mirror self-healing: if the workflow was broken for a
  while, the next successful run pushes the *full* current state — no gap
  to reconcile, no catch-up logic.
- **`concurrency` with `cancel-in-progress: false`:** overlapping merges
  queue instead of racing on the push; nothing is cancelled, so every
  merged state eventually lands.
- **Auth:** `HA_CONFIG_TOKEN` is a fine-grained PAT with contents:write on
  `britter/ha-config` only. The workflow's own `GITHUB_TOKEN` is pinned to
  `contents: read` — it never needs write access to this repo.
- **Branch protection on `ha-config`:** none needed — the only writer is
  this workflow; the device holds a read-only deploy key. If protection is
  ever added, the PAT owner needs a bypass rule.
- **Failure behavior:** a failed run means the device drifts stale until
  the next push to `home-assistant/**` — never an outage. Detection is
  GitHub's failure email; fixing the workflow and re-running (or pushing
  any commit) catches the device up, because the split always reflects the
  complete current state.

## Semantics after rollout

- Git wins: UI edits to `configuration.yaml` are reverted on the next
  poll (≤5 min). Making a UI edit is a mistake by definition — edit the
  repo instead. Device-side emergency edits must be back-ported to the
  repo immediately.
- `.storage/`, `secrets.yaml`, the recorder DB stay device-local and
  untouched (`git_command: reset --hard` only touches tracked files).
- Restart = brief HA outage on each applied change; acceptable, gatus
  tolerates the ~1 min window.
- Rollback = `git revert` in this repo; the mirror and device follow.

### What lives in `/config`, and what happens to it

| File / dir | What it is | Fate |
|---|---|---|
| `configuration.yaml` | the managed file | tracked, deliberate |
| `secrets.yaml` | tokens, API keys | untracked; untouched by `reset`, restored on first clone |
| `.storage/` | device/entity/area registries, integrations, UI dashboards, auth, ZHA/MQTT state | untracked; untouched by `reset`, restored on first clone |
| `home-assistant_v2.db` (+`-wal/-shm`) | recorder history | untracked; same |
| `automations.yaml`, `scripts.yaml`, `scenes.yaml` | **UI-maintained** automations/scripts | untracked; same |
| `blueprints/`, `custom_components/` (HACS), `www/community/`, `themes/`, `www/`, `media/`, `tts/` | UI/downloaded content | untracked; same |

**Rule: the device repo tracks `configuration.yaml` (plus README and
`.gitignore`) and nothing else.** The UI-maintained YAML files
(`automations.yaml`, `scripts.yaml`, `scenes.yaml`, dashboards) are
owned by the device; once any of them becomes tracked,
`git_command: reset` silently clobbers the device's copy every poll —
that is the one way this setup can destroy UI work. The
`home-assistant/README.md` must state this rule, and any PR adding a
second tracked file should be treated as a design change, not a tweak.

## Failure modes

| Failure | Effect | Detection |
|---|---|---|
| Sync workflow breaks | Device runs stale config; no outage | GitHub failure email; stale drift |
| ha-config repo deleted/blocked | Add-on errors, device keeps last state | Add-on log; gatus unaffected |
| Invalid config merged | Add-on validation fails before restart, keeps old config | Add-on log; GitHub CI should catch first |
| `directions` IP changes | 400 through proxy again | gatus red in ≤5 min; tofu comment points at the UI path. Fix: Settings > System > Network > HTTP server — and confirm the post-restart dialog **within 5 minutes**, or HA reverts the change (2026.8 pending/stable mechanism) |

## Out of scope / future

- Managing secrets.yaml (needs sops-on-HAOS or NixOS migration).
- Automations/dashboards/registries via `toelke/homeassistant` or UI.
- **Proxy-trust config in code:** impossible on HAOS — HA 2026.8 moved
  it to UI/`.storage/http` permanently. The only path to expressing it
  declaratively is migrating HA to the NixOS
  `services.home-assistant` module, which would also retire the
  add-on, the mirror, and the device-local secrets entirely.
