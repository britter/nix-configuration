# nix-configuration

## Useful links

- [NixOS Search](https://search.nixos.org/packages)
- [Available programs](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/programs)
- GNOME
  - [NixOS manual entry](https://nixos.org/manual/nixos/stable/#chap-gnome)
  - [NixOS wiki entry](https://nixos.wiki/wiki/GNOME)

## Initializing a new device

1. Install the latest NixOS release
2. Clone this repository
3. Override and commit the `hardware-configuration.nix` file from `etc/nixos/hardware-configuration.nix`
4. Replace `/etc/nixos` with a symbolic link to the host directory in the repository clone
