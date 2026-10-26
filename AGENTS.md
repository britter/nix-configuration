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

## Run the checks

After making any change, run `nix flake check` and fix every issue it
reports before considering the work done. This evaluates all hosts,
home-manager configurations, packages, and the treefmt formatting check.
It is the closest thing this repo has to a test suite.

### GitHub Actions `.github/workflows/`

- Jobs that use the self-hosted pool must declare
  `runs-on: [self-hosted, trusted]`; never a bare `self-hosted`.
- No workflow may use `pull_request_target`.
- Every referenced third-party action must be pinned to a full commit SHA
  and pre-registered in the repository's Actions allow-list (Settings →
  Actions → General; UI-only). NixOS pipelines (`ci-build.yaml`,
  `lint.yaml`) ignore `tofu/**` and `docs/**`; the tofu pipelines trigger
  only on `tofu/**` plus shared files. Details in `docs/homelab.md`.
