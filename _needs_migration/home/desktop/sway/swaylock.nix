{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.home.desktop.sway.swaylock;
in
{
  options.my.home.desktop.sway.swaylock = {
    enable = lib.mkEnableOption "swaylock";
  };
  config = lib.mkIf cfg.enable {
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
        screenshots = true;
        daemonize = true;
        ignore-empty-password = true;
        clock = true;
        indicator = true;
        effect-blur = "10x5";
        effect-vignette = "0.5:1";
      };
    };
  };
}
