{ config, ... }:
{
  flake.modules.nixos.system-base = {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
      };
    };

    nixpkgs.overlays = [ config.flake.overlays.default ];
    nixpkgs.config.allowUnfreePackages = config.flake.allowUnfreePackages;
  };
}
