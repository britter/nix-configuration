# Nix cheatsheet

Generic Nix command reference — nothing specific to this repository. Collected
over the years and moved out of the README.

## General

**Show store location of a package**

```shell
nix build <package> --print-out-paths --no-link
```

Where `<package>` would be something like `nixpkgs#cowsay`.

**Run a command without installing it**

```shell
nix run <package> -- <args>
```

Where

- `<package>` would be something like `nixpkgs#exa`
- `<args>` would be something like `--tree --level 4` (in the case of exa).

Note that the `<package>` and `<args>` need to be separated by `--`.

**Getting a package hash**

From URL:

```shell
nix run nixpkgs#nix-prefetch fetchurl --url <url>
```

From git/GitHub:

```shell
nix run nixpkgs#nix-prefetch-git <url>
nix run nixpkgs#nix-prefetch-github <owner> <repo>
```

This will download the URL/git repository to the store and print the resulting hash.

## Flakes

**Switch to a machine configuration by host name**

```shell
sudo nixos-rebuild switch --flake ".#<host>"
```

**Retrieve flake metadata**

```shell
nix flake metadata <flake url>
```

Flake url can be something like

- `.` (flake in CWD)
- `github:nixos/nixpkgs/nixos-unstable`

**Initialize a new flake**

```shell
nix flake init --template <template name>
```

**Update a specific flake input**

```shell
nix flake lock --update-input <input name>
```

**Update flake with commit**

```shell
nix flake update --commit-lock-file
```

**Explore a flake**

```shell
nix flake show <flake url>
```
