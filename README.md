# nix-configuration

Flake based Nix configuration for my machines.

## Useful commands

### General

**Show store location of a module**

```shell
nix build <package> --print-out-paths --no-link
```

Where `<package>` would be something like `nixpkgs#cowsay`

**Run command without installing or nix-shell**

```shell
nix run <package> -- <args>
```

Where

- `<package>` would be something like `nixpkgs#exa`
- `<args>` would be something like `--tree --level 4` (in the case of exa).

Note that the `<package>` and `<args>` need to be separated by `--`

**Getting a package hash**

From URL:

```shell
nix run nixpkgs#nix-prefetch-url <url>
```

From git/GitHub:

```shell
nix run nixpkgs#nix-prefetch-git <url>
```

This will download the URL/git repository to the store and print the resulting hash.

### Flakes

**Switch to a machine configuration by host name**

```shell
sudo nixos switch --flake ".#<host>"
```

**Retrieve flake meta data**

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

**Update specific flake input**

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

## Initializing a new machine

1. Install the latest NixOS release
2. Clone this repository using a nix-shell that has git `nix-shell -p git`
3. Create a new folder under `hosts` that's named after the host.
4. Copy the `configuration.nix` and `hardware-configuration.nix` files from `etc/nixos/` into the new directory.
5. Add the new machine to `flake.nix`.
6. Repace `/etc/nixos` with a symbolic link to cloned repository.
7. Run `sudo nixos-rebuild switch --flake` to enable the flake based configuration for the new machine.

## Useful links

- [NixOS Search](https://search.nixos.org/packages)
- [Available programs](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/programs)
- GNOME
  - [NixOS manual entry](https://nixos.org/manual/nixos/stable/#chap-gnome)
  - [NixOS wiki entry](https://nixos.wiki/wiki/GNOME)
- [Flakes book](https://github.com/ryan4yin/nixos-and-flakes-book)
- [Using Flatpack](https://github.com/asininemonkey/nixos/blob/main/flatpak.nix)
- [Nix Configuration Examples](https://nixos.wiki/wiki/Configuration_Collection)
  - https://github.com/fortuneteller2k/nix-config
  - https://github.com/wiedzmin/nixos-config
  - https://github.com/jhol/dots
  - https://github.com/genebean/dots
  - https://github.com/icecreammatt/nixfiles
- [nix-jabba](https://codeberg.org/raboof/nix-jabba)
- [devenv.sh](https://devenv.sh)
- Tools
  - [lazygit](https://github.com/jesseduffield/lazygit)
- Raspberry Pi
  - [SD Image builder](https://github.com/Robertof/nixos-docker-sd-image-builder)
  - [pi-hole flake](https://github.com/mindsbackyard/pihole-flake)
