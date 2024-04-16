{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.modules.nix;
in {
  options.my.modules.nix = {
    enable = lib.mkEnableOption "nix";
  };

  config = lib.mkIf cfg.enable {
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
  };
}
