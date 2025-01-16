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
        options = "--delete-older-than 14d";
      };
      settings = {
        experimental-features = ["nix-command" "flakes"];
        auto-optimise-store = true;
      };
    };

    nixpkgs = {
      overlays = [inputs.self.overlays.${system}];
      config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) allowedUnfreePkgs;
    };
  };
}
