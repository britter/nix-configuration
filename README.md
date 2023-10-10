# nix-configuration

Flake based Nix configuration for my machines.

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
