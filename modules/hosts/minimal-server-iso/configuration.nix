{ inputs, config, ... }:
{
  flake.modules.nixos.minimal-server-iso =
    {
      pkgs,
      ...
    }:
    {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        config.flake.modules.generic.systemConstants
        config.flake.modules.nixos.ssh-access
      ];

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      environment.systemPackages = with pkgs; [
        neovim
        git
      ];

    };
}
