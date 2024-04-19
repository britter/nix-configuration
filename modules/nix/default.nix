{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  system = config.my.host.system;
in {
  config = {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
      settings = {
        experimental-features = ["nix-command" "flakes"];
        auto-optimise-store = true;
      };
    };

    nixpkgs = {
      hostPlatform = lib.mkDefault system;
      overlays = inputs.self.overlays.${system};
    };
  };
}
