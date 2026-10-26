---
name: nix-expert
description: |
  Working rules for editing a Nix flake repository such as
  ~/github/britter/nix-configuration, including where to look up options and
  functions. Use when creating, renaming, moving, or deleting files there.
  Use when nix eval/build/nixos-rebuild behaves confusingly after a
  structural change. Use when looking up NixOS/Home Manager options or
  nixpkgs lib functions. Core rule: stage new files with `git add`
  immediately, or evaluation will not see them.
---
# Editing the Nix Configuration

Nix evaluates flakes from git-tracked files only. On a dirty worktree,
`nix eval`, `nix build`, and `nixos-rebuild` see your edits and your
deletions, but **untracked files do not exist at all**. This produces
misleading errors far from the cause. Examples: "undefined variable
'some-module'", options that vanish, modules silently not applied, attributes
that evaluate fine in one command and fail in the next.

## Rules

- Create or move a file, then `git add` it right away. Do not postpone the
  `git add` to commit time or to the next rebuild. Add it while the change
  is fresh.
- After any structural change (new module, moved file, renamed directory),
  first re-run the exact eval or build that matters. Check that the error
  changed before you hunt for a bug in the content.
- When an eval fails oddly, check `git status` for untracked paths before
  reading the stack trace.
- To reference an executable, use `${lib.getExe pkgs.<package>}` rather than
  interpolating `${pkgs.<package>}/bin/<name>` by hand. It resolves the
  binary through `meta.mainProgram`. A wrong package then fails at evaluation
  time instead of producing a path that does not exist. Use `lib.getExe'
  pkgs.<package> "<name>"` when the binary is not the main program. Older
  occurrences of `${pkgs.x}/bin/x` in the repo do not follow the preferred
  pattern.

## Look things up before guessing

Option and function names from memory are usually wrong. Use these sources:

- Functions (builtins and nixpkgs lib): fetch
  https://noogle.dev/api/v1/data once per session (about 4 MB). Cache it
  in a scratch file for the rest of the session. Entries are
  `{ meta: { title, path, aliases, signature, ... }, content }` with titles
  like "lib.mapAttrs" or "builtins.baseNameOf". Find candidates with jq:
  `jq '.data[] | select(.meta.title == "lib.mapAttrs")'`, or match loosely on
  `.meta.title`, `.meta.path`, and `.meta.aliases`. The docs text is in
  `.content`.
- NixOS options: `man configuration.nix`
- Home Manager options: `man home-configuration.nix`
- nixvim options: `man nixvim`
  This host has all three man pages installed. Run them non-interactively
  so the pager cannot block you, e.g.
  `MANWIDTH=100 man configuration.nix | rg -m5 -A2 'services\.openssh\.enable'`.
- Nix language and builtins reference: https://nixos.org/manual/nix/stable/
- nixpkgs manual (packaging, stdenv, overrides):
  https://nixos.org/manual/nixpkgs/unstable/