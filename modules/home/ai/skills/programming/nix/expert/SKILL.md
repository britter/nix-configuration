---
name: programming.nix.expert
description: |
  Working rules for editing a Nix flake repository such as
  ~/github/britter/nix-configuration, including where to look up options and
  functions. Use whenever creating, renaming, moving, or deleting files there,
  when nix eval/build/nixos-rebuild behaves confusingly after a structural
  change, or when looking up NixOS/Home Manager options or nixpkgs lib
  functions. Core rule: stage new files with `git add` immediately, or
  evaluation will not see them.
---
# Editing the Nix Configuration

Flakes are evaluated from git-tracked files only. On a dirty worktree,
`nix eval`, `nix build`, and `nixos-rebuild` see your edits and your
deletions, but **untracked files do not exist at all**. This produces
misleading errors far from the cause: "undefined variable 'some-module'",
options that vanish, modules silently not applied, attributes that evaluate
fine in one command and fail in the next.

## Rules

- Create or move a file, then `git add` it right away. Not at commit time,
  not before rebuilding. Immediately, while the change is fresh.
- After any structural change (new module, moved file, renamed directory),
  first re-run the exact eval or build that matters and check the error
  changed, before hunting for a bug in the content.
- When an eval fails oddly, check `git status` for untracked paths before
  reading the stack trace.

## Look things up before guessing

Option and function names from memory are usually wrong. Use these sources:

- Functions (builtins and nixpkgs lib): fetch
  https://noogle.dev/api/v1/data once per session (about 4 MB) and cache it
  in a scratch file for the rest of the session. Entries are
  `{ meta: { title, path, aliases, signature, ... }, content }` with titles
  like "lib.mapAttrs" or "builtins.baseNameOf". Find candidates with jq:
  `jq '.data[] | select(.meta.title == "lib.mapAttrs")'`, or match loosely on
  `.meta.title`, `.meta.path`, and `.meta.aliases`. The docs text is in
  `.content`.
- NixOS options: `man configuration.nix`
- Home Manager options: `man home-configuration.nix`
- nixvim options: `man nixvim`
  All three man pages are installed on this host. Run them non-interactively
  so the pager cannot block you, e.g.
  `MANWIDTH=100 man configuration.nix | rg -m5 -A2 'services\.openssh\.enable'`.
- Nix language and builtins reference: https://nixos.org/manual/nix/stable/
- nixpkgs manual (packaging, stdenv, overrides):
  https://nixos.org/manual/nixpkgs/unstable/
