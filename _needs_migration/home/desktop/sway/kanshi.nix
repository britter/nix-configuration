{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.home.desktop.sway.kanshi;
in
{
  options.my.home.desktop.sway.kanshi = {
    enable = lib.mkEnableOption "kanshi";
  };
  config = lib.mkIf cfg.enable {
    services.kanshi = {
      enable = true;
      settings =
        let
          framework-13 = "BOE NE135A1M-NY1 Unknown";
          lg32 = "LG Electronics LG HDR 4K 111NTBKD6957";
        in
        [
          {
            profile.name = "home";
            profile.outputs = [
              {
                criteria = lg32;
                status = "enable";
                position = "0,0";
              }
              {
                criteria = framework-13;
                status = "enable";
                position = "480,2160";
              }
            ];
            profile.exec = [
              "${pkgs.sway}/bin/swaymsg workspace 10, move workspace to eDP-1"
              "${pkgs.sway}/bin/swaymsg workspace 1, move workspace to DP-2"
            ];
          }
        ];
    };
  };
}
