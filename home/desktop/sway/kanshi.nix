{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.home.desktop.sway.kanshi;
in {
  options.my.home.desktop.sway.kanshi = {
    enable = lib.mkEnableOption "kanshi";
  };
  config = lib.mkIf cfg.enable {
    services.kanshi = {
      enable = true;
      settings = let
        pulse-14 = "Tianma Microelectronics Ltd. TL140ADXP24-0 Unknown";
        lg32 = "LG Electronics LG HDR 4K 111NTBKD6957";
      in [
        {
          profile.name = "home";
          profile.outputs = [
            {
              criteria = lg32;
              status = "enable";
              position = "0,0";
              scale = 1.5;
            }
            {
              criteria = pulse-14;
              status = "enable";
              # positioned at the bottom honoring the scale of 1.5: y = 2160 / 1.5 = 1440
              position = "960,1440";
            }
          ];
          profile.exec = [
            "${pkgs.sway}/bin/swaymsg workspace 0, move workspace to eDP-1"
            "${pkgs.sway}/bin/swaymsg workspace 1, move workspace to DP-2"
          ];
        }
      ];
    };
  };
}
