# Notes for coding agents

This repository is the declarative configuration for all of my machines. It
holds a set of NixOS hosts (a desktop laptop and several home servers) plus a
standalone home-manager configuration. Every machine, user environment,
service, and dotfile lives in a single Nix flake. Do not configure anything
imperatively on the machines themselves.

## Structure: dendritic pattern

The flake uses my own flavor of the dendritic Nix pattern (flake-parts plus
import-tree). See
https://britter.dev/blog/2026/05/11/exploring-the-dendritic-nix-pattern/
for the reasoning behind it.

The central concept: everything is a named aspect. Importing an aspect
enables it — as long as the aspect only configures existing NixOS or
home-manager options. A host gets a feature by listing it in its imports.
New functionality becomes its own named aspect so that hosts can pull it in.

The exception is features for which no module exists upstream. There I write
my own NixOS or home-manager module as its own base aspect, written in
the conventional style of the ecosystem (`mkEnableOption`, disabled by
default, `mkPackageOption`, ...) so that it could be upstreamed to
nixpkgs or home-manager as-is. Treat these base aspects as my own
extensions to nixpkgs/home-manager (e.g. `nono-base.nix` providing
`programs.nono`). The matching base layer imports them unconditionally
so the options exist everywhere. A separate, ordinary aspect then enables and
configures the feature: it imports nothing but sets the options (e.g.
`ai-agents.nix` setting `programs.nono.enable = true`). Hosts pull in
that aspect.

import-tree auto-imports every `.nix` file under `modules/` as a flake-parts
module. There is no central list of imports. Aspects register in:

- `flake.modules.nixos.<name>` — NixOS aspects
- `flake.modules.homeManager.<name>` — home-manager aspects

Hosts are aspects too: `modules/hosts/<name>/configuration.nix` defines
`flake.modules.nixos.<name>` as an import list of aspect names plus
host-specific settings. A small per-host `flake-parts.nix` turns that aspect
into an actual `nixosConfigurations.<name>` entry via `flake.lib.mkNixos`.

Conventions and patterns:

- One feature spanning NixOS and home-manager lives in a single file that
  sets both registry entries. The NixOS side pulls in its home-manager side
  via `home-manager.sharedModules`.
- Aspects that need parameters are factories: register them under
  `flake.factory.<name>` and call them at the import site, e.g.
  `(config.flake.factory.sops { secretsFile = ./secrets.yaml; })`.
- Generic service aspects (e.g. `modules/nixos/nextcloud.nix`) stay
  host-agnostic. Per-host instances follow the base-plus-instance pattern:
  `modules/hosts/<host>/services/<name>.nix` defines `<service>-on-<host>`,
  which imports the generic aspect and adds host specifics such as storage
  paths, secrets, and proxy registration. Hosts import the `-on-<host>`
  variants, never the generic aspect directly.
- Import aspects that declare new options for other aspects to set (like
  `https-proxy`, which owns `services.https-proxy.*`) once in
  the matching system-type base (`system-base`, `system-desktop`,
  `system-server`). The options then exist everywhere you may use them.
- Dependencies between aspects must otherwise be explicit: import the aspect
  you need, or communicate through the options of a small dedicated
  interface aspect. Never rely on some other file having imported something
  for you.

Exceptions to "every feature is its own named aspect":

- Hardware definitions contribute implicitly to their host aspect. Files
  like `modules/hosts/<host>/hardware/hardware.nix` set the same registry
  key as the host's `configuration.nix`, and the module system merges them.
  There is no sense in making hardware optional, so hardware needs no named
  aspect or import entry.
- Very large configurations decompose into multiple unnamed parts that all
  set one registry key and merge into a single aspect. The nixvim config
  works this way: every file under `modules/home/nvim/` sets
  `flake.modules.homeManager.nvim`, and together they form one editor setup.

import-tree consequences worth remembering:

- Plain modules (files that do not set flake-parts options) must not live
  under `modules/`. Prefix them with `_` to keep import-tree from importing
  them, e.g. `_restic-constants.nix`.
- import-tree skips files whose path contains a `_`-prefixed segment, and it
  skips all non-.nix files. This is why things like `secrets.yaml` can sit
  next to host configurations.
- Local packages live in `packages/<name>/` as plain derivations and become
  available as `pkgs.<name>` through `flake.overlays.local-pkgs`.

## Tools used in this configuration

Notable inputs from flake.nix and how they show up:

- nixvim manages Neovim (`modules/home/nvim/`).
  Repository: https://github.com/nix-community/nixvim,
  docs: https://nixvim.dev. To see the init file nixvim actually generates
  from the configured modules, run `nixvim-print-init`. It prints the
  assembled result directly, without a rebuild. Use `man nixvim` to find all
  available nixvim configuration options.
- sops-nix manages secrets (https://github.com/Mic92/sops-nix). Each host
  keeps its own `secrets.yaml` next to its configuration, wired in via the
  sops factory. `.sops.yaml` at the repository root maps host directories
  to age keys.
- disko defines disk layouts per host under
  `modules/hosts/<host>/hardware/` (https://github.com/nix-community/disko).
- comin deploys automatically on servers: it pulls this repository from the
  URL in `systemConstants.configRepo` and switches when the branch moves
  (https://github.com/nlewo/comin).
- nixos-hardware and `hardware.facter` provide per-model hardware
  enablement. See the same `hardware/` directories.
  (https://github.com/NixOS/nixos-hardware,
  https://github.com/numtide/nixos-facter-modules)
- treefmt-nix and pre-commit-hooks gate formatting and linting. Run
  `nix fmt` before committing.
  (https://github.com/numtide/treefmt-nix,
  https://github.com/cachix/git-hooks.nix)

The `# keep-sorted` markers keep the inputs block in flake.nix sorted
alphabetically. Add new inputs in sorted order.

## Plan documents

Work plans live in `docs/plans/<slug>.md` while active. When a plan is
completed, move it with `git mv` to
`docs/plans/archive/YYYY-MM-DD-<slug>.md` so the archive sorts by
completion date automatically.

When you write a plan, follow these rules. They come from writing and
reviewing the migration plans in this directory:

- State the chosen approach early. Answer the obvious alternatives in two
  or three sentences.
- Keep the runbook complete and self-contained. A reader follows the
  runbook alone. Steps must not depend on a summary in another section.
- State the rollout mechanics inside each step. comin switches a server
  as soon as `main` moves. Merges and data moves therefore interact. Make
  that interaction explicit where it matters.
- Make the order deterministic. Stop or disable the old component first,
  through its own rollout. Then move data. Then switch URLs. Accept the
  downtime window that this creates. A controlled outage is easier to
  reason about than a coincidental overlap.
- Search for every reference to the component that moves: URL patterns,
  secret names, firewall rules, DNS entries, monitoring checks. Write a
  list of the changes. Write a second list of the places that need no
  change, each with its reason. Without a stated reason the reader cannot
  tell whether the check happened.
- Start with the smallest change that solves the problem. Let review cut
  bigger designs.
- Render every repo change as a diff fence. Use an `@@ <path> @@` header
  instead of line numbers. The patch then stays valid when lines shift.
  Mark values that a diff cannot show, such as `ENC[...]` ciphertext, as
  placeholders. State clearly that placeholders are not copyable.
- Run every command before you put it into the plan. Record the results
  that you verified. A command that nobody executed is an unverified
  claim.
- Mark each step as idempotent or not. A delete step that errors on a
  second run must say so.
- Write a Known effects section for every deliberate side effect:
  downtime windows, data gaps, certificate churn, doubled notifications.
  Point each effect at the runbook step that controls it.
- Define rollback per phase. State what each rollback restores. Name the
  step that ends the state-based rollback. It is usually a delete step.
  Put it last.
- Check at every phase boundary. State the expected state after each
  phase. Do not start the next phase before that check passes.
- Keep secret values out of the plan. Name paths, not values. Move
  secrets through pipes, not through manual copying or a clipboard.
- Update the status line and the ✅/⏳ marks as work completes.

## Run the checks

After making any change, run `nix flake check` and fix every issue it
reports before considering the work done. This evaluates all hosts,
home-manager configurations, packages, and the treefmt formatting check.
It is the closest thing this repo has to a test suite.

### GitHub Actions `.github/workflows/`

- Jobs that use the self-hosted pool must declare
  `runs-on: [self-hosted, trusted]`. Never declare a bare `self-hosted`.
- No workflow may use `pull_request_target`.
- All Tofu applies run through gitops. The `tofu-*` pipelines plan on
  pull requests and apply after merge to `main`. Never run `tofu apply`
  locally. Check the changes through the pipeline's plan comment. Local
  tofu work (`init`, `plan`, debugging) is fine. The per-root `.envrc`
  provides the state bucket credentials.
- Pin every referenced third-party action to a full commit SHA.
  Pre-register it in the repository's Actions allow-list (Settings →
  Actions → General, UI only). NixOS pipelines (`ci-build.yaml`,
  `lint.yaml`) ignore `tofu/**` and `docs/**`. The tofu pipelines trigger
  only on `tofu/**` plus shared files. Details in `docs/homelab.md`.
