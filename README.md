# nix-configuration

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

## Initializing a new device

1. Install the latest NixOS release
2. Clone this repository
3. Override and commit the `hardware-configuration.nix` file from `etc/nixos/hardware-configuration.nix`
4. Replace `/etc/nixos` with a symbolic link to the host directory in the repository clone
