{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.modules.gaming;
in {
  options.my.modules.gaming = {
    enable = lib.mkEnableOption "gaming";
  };

  config = lib.mkIf cfg.enable {
    programs.steam.enable = true;
    # run games in an optimized micro compositor
    programs.steam.gamescopeSession.enable = true;

    my.modules.allowedUnfreePkgs = [
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
    ];

    # performance stats overlay
    environment.systemPackages = [
      pkgs.mangohud
    ];

    # requests OS optimizations while gaming
    programs.gamemode.enable = true;
  };
}
