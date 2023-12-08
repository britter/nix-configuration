# TODO

## Next
- GNOME:
  - Add useful extensions, e.g. auto dark mode switcher
  - Remove GNOME software I don't need
- Figure out whether more of Firefox configuration can be declared via nix
  - bookmarks from bookmark menu
  - disable Mozilla data collection
  - See https://discourse.nixos.org/t/help-setting-up-firefox-with-home-manager/23333
- Setup Reaper and Ultraschall
- Configure gpg to trust my own keys? Check the git log with --show-signatures and it will say the key is not trusted.

## After Next
- Revisit tmux copy-mode
- Rename user on pi-hole to bene, to be able to share more config
  - How to set the password?
  - Set SSH public key for login
- Extract more common code from nixos machines into modules, see https://hoverbear.org/blog/declarative-gnome-configuration-in-nixos/
- Move setting up home-manager into host configuration files

## After after Next
- Decide whether to use [Aduard](https://github.com/AdguardTeam/AdGuardHome) or copy/wait for https://github.com/NixOS/nixpkgs/pull/224881
- Look into [Solaar](https://pwr-solaar.github.io/Solaar/) for managing Logi Mouse
- Look into stylix for theming
- [statix linter](https://git.peppe.rs/languages/statix)
- [Pre-commit-hooks.nix](https://github.com/cachix/pre-commit-hooks.nix)

## Later
- Look into Hyprland as an alternative to GNOME
- Look into disko for managing disk partitioning
- Look into impermanence
- Build my CV with [jsonresume-nix](https://discourse.nixos.org/t/jsonresume-nix-build-and-deploy-your-resume-with-nix/34089)
