# Plan: Merge `britter/home-lab` into `nix-configuration`

Status: done (2026-10-26) — executed end to end; see *Outcome* below for the
decisions taken mid-flight and the remaining loose ends.

## Outcome

Executed via three commits/PRs: #315 (merge + `tofu/` moves, all 252 commits
byte-identical), a one-commit caveat from the `required_signatures` ruleset
(`d1abd50`, an old home-lab commit whose signing key no longer exists —
merged via a temporary admin; the clean fix — uploading that key to
GitHub — remains optional), and #317 (the first real tofu pipeline fix:
`unifi_firewall_policy.trusted_to_networks_http` was invalid
`protocol = "all"` + specific ports, fixed to `tcp` ports 80/443).

Deviations from the plan as written:

- DevShell went into `devShells.default` (not a separate `.#tofu`): the tofu
  tools (`opentofu`, `sops`, `jq`, `unifly`) joined the existing shell, so
  per-root `.envrc` files stayed byte-identical and the workflows keep
  `nix develop ../..`. `minio-client` was dropped: nixpkgs marks it insecure.
- Root `secrets.json` became `tofu/secrets.json`; home-lab `.gitignore`'s
  terraform block was folded into this repo's `.gitignore`.
- Repo settings writes 404 via the API for personal-account repos — the
  Actions allow-list/mode `selected` + `sha_pinning_required` and ruleset
  changes had to happen in the web UI; details live in `docs/homelab.md`.
- The runners got the PAT they had, not a new one (access grant on the
  fine-grained PAT; no sops secrets change). Operational note:
  fine-grained PATs expire — update the `github-runners/pat` sops secret
  when the current token nears expiry, or all four runners stop
  re-registering.

Operational learnings worth keeping until they're muscle memory:

- Applies only happen on `main`; PR runs are plan-only.
- Manual controller changes (like deleting a network in the UniFi UI) must
  be reconciled with state: `cd tofu/<root> && tofu state rm <resource>`.
- Use `unifly` to triage controller state (`networks refs <id>`,
  `devices ports <id>`, `clients reservations`); block deletions persist
  until stale reservations/clients are cleared.

Still open roll-out leftovers (none blocking):

- Archive `britter/home-lab` on GitHub; then re-enable Renovate there if
  you disabled it (it is already on for this repo, which is the one that
  matters).
- Optional: push `port-home-lab-72` (the staged, empty parity merge linking
  `home-lab/main`'s final commit into `main`'s ancestry) or delete it.
- Optional: make the JetKVM DHCP reservation tofu-managed in
  `tofu/network/clients.tf` so future controller edits don't surprise
  OpenTofu.

---

## The plan as executed

The home-lab repository (OpenTofu infrastructure: `dns`, `network`,
`object-storage`, `proxmox`) and this repository (NixOS machine
configuration) deal with the same infrastructure and should live in one
repository. Currently they have two unrelated git histories and two
independent GitHub pipelines.

Goals of this merge:

1. Bring the home-lab history into this repository (preserve all commits).
2. Move the home-lab code into a `tofu/` subdirectory here.
3. Port the home-lab GitHub workflows over to this repository.
4. Wire up path filters so tofu pipelines only run for changes under
   `tofu/`, and the existing NixOS pipelines only run for changes outside
   of `tofu/`.
5. Point the self-hosted GitHub runners on `srv-prod-6` at this repository.
6. Reconfigure the repository so external contributions are never executed
   automatically on the self-hosted runners.

## 0. Preconditions / risks

- home-lab remote: `git@github.com:britter/home-lab.git`.
- The tofu state bucket credentials come from sops-encrypted
  `secrets.json` files inside each tofu root, keyed by the
  `github-runners` age key (secret `github-runners/age-key` on srv-prod-6).
  The `.sops.yaml` rules in home-lab must keep working from the new
  location, so `.sops.yaml` moves untouched into `tofu/`.
- The home-lab devShell is at the repository **root**, but each workflow
  calls `nix develop ../` from its working directory. After moving the
  code one level deeper this relative path breaks; workflows must switch
  their devShell reference (see §3).
- Later steps should be done in order; the repository should stay green
  between them where possible.

## 0b. Execution model: AGENT vs. HUMAN steps

Steps are tagged **[AGENT]** and **[HUMAN]**.

- **[AGENT]** steps the agent can carry out on this machine.
- **[HUMAN]** steps the agent cannot do and **must present to the user
  and explicitly ask for confirmation before proceeding past them**.
  Do not skip, simulate, or work around a HUMAN step.

Constraints that make a step HUMAN on this machine:

- The agent cannot run any command requiring **ssh** (including
  `git@github.com:`-style remotes), **gpg**, or **sops** (encrypting or
  re-keying secrets).
- The agent cannot create **git commits** (agent-signed or otherwise).
  It may fetch, stage (`git add`/`git mv`), run `git merge --no-commit`,
  and inspect, but every `git commit` — and therefore every push and
  PR creation — is HUMAN.
- Creating GitHub credentials (fine-grained PATs), clicking through
  GitHub repository settings (collaborators, Actions permissions,
  forking, archiving, Renovate on/off), and any rebuild/switch of a
  production host (srv-prod-6) are HUMAN.

Each section ends with a **Verification** block: run it after that
section is complete and do not start the next section until it passes.

## 1. Merge the history (unrelated histories)

Do this with `git merge --allow-unrelated-histories` so every home-lab
commit stays reachable and `git blame`/`git log` keep working across the
boundary.

1. [AGENT] In `nix-configuration`, prepare the remote: `git remote add
   home-lab https://github.com/britter/home-lab.git` (HTTPS — the agent
   cannot use ssh) and `git fetch home-lab`. If credentials are needed,
   ask the HUMAN to run the fetch.
2. [HUMAN] Freeze both repositories for the merge (merge open PRs or
   note them for rebase). Disable renovate on home-lab first so it
   cannot create new PRs during the migration. Renovate is already
   enabled on this repository; nothing needs to be turned on here (see
   §3 step 4 for what makes renovate pick up the tofu updates after the
   merge).
3. [AGENT] `git merge home-lab/main --allow-unrelated-histories
   --no-commit`. Resolve conflicts by keeping this repository's files
   where both sides have them (`.github/renovate.json` exists in both —
   merge them into one config with the combined settings: tofu
   providers from home-lab and `:automergeAll` for this repo). Leave
   everything staged for the HUMAN to commit.
4. [AGENT] Continue with §2 in the same branch. Do **not** push; the
   combined move+merge becomes one PR so `main` is never in a broken
   state.
5. [HUMAN] Commit and push the branch, open the PR, merge it.
6. [HUMAN] After the PR is merged: archive the `britter/home-lab`
   GitHub repo (read-only), keep the remote definition for posterity or
   remove it. Re-enable renovate on this repository.

**Verification (§1):** all checks [AGENT] unless tagged.

- [AGENT] `git log --oneline home-lab/main` and
  `git log --oneline home-lab/main --not main` produce the expected
  history; after merge, home-lab's commit range is reachable from
  `main` (`git merge-base --is-ancestor home-lab/main main` returns 0).
- [AGENT] `.github/renovate.json` is one file with both repos'
  settings (`:automergeAll` present) and valid JSON
  (`jq . .github/renovate.json`).
- [AGENT] At this stage the working tree contains a byte-identical
  copy of home-lab at the top level: `git diff home-lab/main --stat`
  shows differences only in the files this repository already owned
  (`.github/renovate.json`), and none of the home-lab files
  (`dns/`, `network/`, `object-storage/`, `proxmox/`, `.sops.yaml`,
  `.envrc` per root, root `.envrc`) show a diff. (The top-level
  cleanliness check after the moves is §2's verification.)
- [HUMAN, read confirmation] The remote `britter/home-lab` shows
  **archived** on GitHub.

## 2. Move the code into `tofu/`

- [AGENT] `git mv` the four tofu roots into `tofu/`:
  - `dns/` → `tofu/dns/`
  - `network/` → `tofu/network/`
  - `object-storage/` → `tofu/object-storage/`
  - `proxmox/` → `tofu/proxmox/`
- [AGENT] `git mv` the `.envrc` files: home-lab has a root `.envrc`
  (`use flake`) plus one `.envrc` per tofu root that decrypts
  `secrets.json` and exports the state-bucket S3 credentials. The
  per-root ones move unchanged. The root `.envrc` referenced the
  home-lab root flake, so its `use flake` line must be updated to the
  new devShell location (`use flake .#tofu` on this repo per Option A in
  §3, or `../tofu/flake.nix` per Option B).
- [AGENT] `.sops.yaml`: home-lab has exactly **one** `.sops.yaml` at the
  repo root. It is moved, unchanged, to `tofu/.sops.yaml` — that single
  file keeps covering all four tofu roots' `secrets.json` files (its
  `path_regex` rules are relative to where the file sits), so no merge
  or splitting is needed.
- [AGENT] Keep this repository's top level untouched otherwise:
  `flake.nix`, `modules/`, `docs/`, `packages/` stay where they are.
- [AGENT] README: add a short `tofu/README.md` pointing at the per-root
  READMEs (they move along with the directories).
- [AGENT] Structural check that sops rules still line up
  (`.sops.yaml` uses path-relative rules; moving directory + rules file
  together keeps them valid). The **decryption** smoke test itself is
  HUMAN (see below).

**Verification (§2):** all checks [AGENT] unless tagged.

- [AGENT] `git status --short` shows moves staged into `tofu/**` only;
  the repository root contains none of the moved home-lab entries:
  `dns/`, `network/`, `object-storage/`, `proxmox/`, `.sops.yaml`, and
  root `.envrc` are gone from the top level and exist under `tofu/`.
- [AGENT] `tofu/.sops.yaml` covers all four roots: for each
  `tofu/<root>/secrets.json` its `path_regex` matches
  (`rg 'path_regex' tofu/.sops.yaml`).
- [HUMAN, confirm on request] `cd tofu/<root> && sops -d secrets.json >
  /dev/null` succeeds for each root — the agent cannot run sops, so ask
  the user to run these four decryptions and report the result.

## 3. Port and wire up the pipelines

home-lab has five workflows: a reusable `_tofu.yaml` plus thin wrappers
`tofu-dns.yaml`, `tofu-network.yaml`, `tofu-object-storage.yaml`,
`tofu-proxmox.yaml`. This repo has `ci-build.yaml` and `lint.yaml`.
Port them into `.github/workflows/` of this repository:

1. [AGENT] `git mv` all five home-lab workflow files into
   `.github/workflows/` (adjust `_tofu.yaml` to be a proper reusable
   workflow with `on: workflow_call` if it is invoked by path — verify
   the trigger config during the port).
2. [AGENT] Fix the devShell path: the workflows run `nix develop ../`
   to reach the root flake. The tofu code no longer sits next to a root
   flake, so either:
   - **Option A (recommended):** move/copy the home-lab devShell
     (opentofu, sops, jq, unifly, pre-commit-hooks, garage/minio client)
     into this repository's flake as `devShells.<system>.tofu` (or a
     `flake.factory` style helper), and change workflows to
     `nix develop .#<name>` / `nix develop ../.#...` from the
     `tofu/<root>` working directory. Check in the tofu pre-commit
     config (nixfmt, terraform-format) and fold it into this repo's
     treefmt or keep it per-directory.
   - Option B: keep a minimal `flake.nix` inside `tofu/` providing the
     devShell, and use `nix develop ../tofu` in workflows.
3. [AGENT] Path filters (`on.push.paths` / `pull_request.paths`):
   - `tofu-<root>.yaml`: change paths from e.g. `dns/**` to
     `tofu/dns/**`; also cover `tofu/.sops.yaml`, the per-root
     `tofu/<root>/.envrc` files, and the shared devShell file
     (whichever flake provides it) so a shell change re-runs all tofu
     jobs. The root `tofu/.envrc` only matters for local dev, not CI.
   - `_tofu.yaml` keeps its current path filters if it directly
     triggers per directory; if it is reusable-only, drop paths there
     and keep them on the wrappers.
   - `ci-build.yaml` and `lint.yaml`: add `paths-ignore:
     ['tofu/**', 'docs/**']` so NixOS pipelines do not run for
     tofu-only changes (and, as a cleanup, also not for docs-only
     changes). Decide explicitly whether `nix flake check` should
     ignore tofu (it no longer covers it once the code left the root
     flake) — yes, if Option A keeps the tofu roots out of the main
     flake outputs.
   - Concurrency: keep each root's `tofu_latch_<dir>` concurrency group
     so applies stay serial; no name collisions with this repo's jobs.
4. [AGENT] Renovate: both repos already use nearly identical configs
   (home-lab adds nothing except dropping `:automergeAll`). Keep this
   repository's `.github/renovate.json` unchanged as-is. No extra
   config is needed for tofu: renovate's terraform (hcl) manager is
   enabled by `config:best-practices` and picks up `tofu/**/*.tf`
   automatically, so it will start updating provider versions
   (cloudflare, minio, …) once the files land under `tofu/`. If Option
   B (separate `tofu/flake.nix`) is chosen, the existing weekly
   `lockFileMaintenance` covers that `tofu/flake.lock` too. Optionally
   add an explicit `fileMatch` for `tofu/**/*.tf` to the terraform
   manager to scope it, but it is not required.

**Verification (§3):** all checks [AGENT].

- `nix fmt` / `nix flake check` on this repository pass.
- Every `.github/workflows/*.yaml` parses (e.g. `yq` round-trips them
  without error).
- Grep the path filters: for a sample of paths, `git diff --name-only
  <base>` classifies changes into `tofu/**` vs. everything else, and
  each workflow's trigger list matches that classification (this can be
  checked statically by comparing paths lists in the YAML files against
  the directories).
- No workflow in the repo uses `pull_request_target`.
- All workflows that run on the self-hosted pool specify
  `runs-on: [self-hosted, trusted]` (see §5).

## 4. Point the srv-prod-6 runners at this repository

The four runners on `srv-prod-6` (`services.github-runners.nixos-runner-1..4`,
factory `flake.factory.github-runners { count = 4; }`) are currently
registered against `https://github.com/britter/home-lab` via the sops
secret `github-runners/pat`.

1. [HUMAN] Create a fine-grained GitHub PAT for this repository
   (`britter/nix-configuration`, Actions: read/write, Contents: read)
   — the agent cannot mint credentials. Share the token value with the
   agent only if the agent should write it into sops; see next step.
2. [HUMAN] Update the sops secret `github-runners/pat` in
   `modules/hosts/srv-prod-6/secrets.yaml` to hold the new PAT — sops
   re-encryption requires the age key and cannot be run by the agent.
   If decryption-only inspection is enough, the agent may read the
   file structurally but never decrypt, encrypt, or re-key.
3. [AGENT] Update `modules/nixos/github-runners.nix` if the repo URL is
   hard-coded there (it currently references `britter/home-lab`); the
   runner module uses `replace = true`, so switching the URL
   re-registers on the first activation.
4. [HUMAN] Apply the configuration to srv-prod-6
   (`nixos-rebuild switch` or via comin).
5. [AGENT] Sanity-check one tofu plan PR end-to-end once runners are
   live (sops decryption on the runner works via exported
   `SOPS_AGE_KEY_FILE`).

**Verification (§4):** run after the [HUMAN] rebuild; confirm the
runner-visible parts with the user (the agent cannot ssh to srv-prod-6).

- [HUMAN, read confirmation] The runners show up on
  https://github.com/britter/nix-configuration (Settings → Actions →
  Runners) with labels `nixos, x86_64, trusted`, and the four
  homelab-registered entries are gone or overridden (`replace = true`).
- [AGENT] `rg -n 'britter/home-lab' modules/` returns nothing.
- [AGENT] A runner-picking PR (`runs-on: [self-hosted, trusted]`) is
  scheduled instead of queued forever; listen via
  `gh run watch` or ask the user to confirm on the run page.
- [AGENT] The tofu plan job in that PR comments its plan on the PR.

## 5. Keep external contributions off the self-hosted runners

The reality of the repository: outside contributions are effectively
none — the only external "contributor" is Renovate. So instead of
building a multi-layer trust model, close the door entirely:

1. [HUMAN] **No outside collaborators.** Keep the repository
   collaborator-restricted (Settings → Collaborators: only `britter`,
   or keep the repo private if it is). No collaborator invite for
   regular accounts, no org write access beyond the owner.
2. [AGENT] Confirm the workflows treat Renovate like any other branch
   (it acts with its own credentials and opens branches in the
   repository itself, so its PRs are not fork PRs, and `:automergeAll`
   keeps working). No special handling needed.
3. [HUMAN] **Fork-PR fallback (defense in depth).** If the repository
   is public and someone forks it anyway, external PRs could still run
   CI. Keep the kill-switch settings even though they should never
   trigger:
   - Settings → Actions → *Fork pull request approvals from outside
     collaborators*: **require approval for everyone**.
   - Never use `pull_request_target` in any workflow (none today —
     keep it that way).
4. [AGENT] **Split runner pools by trust.** The self-hosted runners get
   an additional label `trusted` (add to `extraLabels` in
   `modules/nixos/github-runners.nix`). The tofu workflows use
   `runs-on: [self-hosted, trusted]`. Every self-hosted runner
   implicitly carries the built-in `self-hosted` label (which cannot be
   removed), so a job left on bare `self-hosted` `runs-on` would
   universally match our pool; requiring the extra `trusted` label is
   what keeps routing precise.
5. [HUMAN] **Actions permissions:** restrict which actions can run on
   the repo (Settings → Actions → general → Allow only approved
   actions, pinning to SHAs, as already done in this repo's workflows)
   so third-party marketplace actions cannot be smuggled onto the
   runners.
6. [AGENT] Because the runners live on a production host with secrets
   (age key, state bucket creds), also confirm the `github-runner` user
   cannot reach anything else than intended: it is a fixed system user
   with `nix.settings.trusted-users` membership — acknowledge that this
   means any runner user can install arbitrary Nix packages as root via
   nix build/trusted access and document this residual risk in
   `docs/homelab.md`.

**Verification (§5):** all checks [AGENT] unless tagged.

- [AGENT] `rg -n 'pull_request_target' .github/workflows/` → no hits.
- [AGENT] `rg -n 'runs-on' .github/workflows/` — every job that should
  hit the self-hosted pool uses `[self-hosted, trusted]`; no job uses
  bare `self-hosted`.
- [HUMAN, read confirmation] Settings → Collaborators shows only
  `britter` (+ app keys); the fork-PR approval requirement is active;
  the actions allow-list is active and every referenced action is
  SHA-pinned.
- [AGENT] `rg -n 'residual risk|trusted-users' docs/homelab.md` finds
  the documented risk note.

## 6. Roll-out checklist (ordered)

1. [HUMAN] Disable renovate on home-lab; finish open home-lab PRs.
2. [HUMAN] Commit and push the branch with the unrelated-history merge
   + moves into `tofu/` (§1–§2); CI temporarily red for tofu pipelines
   is acceptable here because workflows only start running after they
   exist in this repo.
3. [HUMAN] Commit and push the ported workflows + devShell + renovate
   (§3), path filters on.
4. [HUMAN] Switch runners to this repository (§4): PAT, sops secret,
   `nixos-rebuild switch` on srv-prod-6.
5. [HUMAN] Hardening on GitHub settings per §5.
6. [AGENT] Run the final verification sweep (below).
7. [HUMAN] Archive `britter/home-lab`.
8. [AGENT] Document the new layout in this repo's README and
   `docs/homelab.md`.

**Final verification (§6) — expected end state; all checks [AGENT]
unless tagged:**

- [AGENT, with a test PR] A PR touching `tofu/dns` runs exactly one
  tofu pipeline and no NixOS pipelines; a PR touching `modules/` runs
  ci-build + lint and no tofu pipelines; a PR touching both runs both
  sets.
- [AGENT] Tofu plan results are commented on the PR; applies happen
  only on `main`, serially (per-root concurrency latches intact).
- [AGENT] Runners are registered against `britter/nix-configuration`
  (run exists and is green). [HUMAN, read confirmation] Settings show
  labels `nixos, x86_64, trusted` on the runners and the
  renovate-only external-access model holds (collaborator settings,
  fork-PR approval fallback, actions allow-list).
- [AGENT] README and `docs/homelab.md` describe `tofu/` and the
  layout.
