{
  config,
  lib,
  inputs,
  ...
}: let
  inherit (config.my.host) system;
  inherit (config.my.modules) allowedUnfreePkgs;
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
      config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) allowedUnfreePkgs;
    };
  };
}
