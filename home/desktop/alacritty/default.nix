{
  config,
  lib,
  ...
}: let
  cfg = config.my.home.desktop.alacritty;
in {
  options.my.home.desktop.alacritty = {
    enable = lib.mkEnableOption "alacritty";
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        font = {
          size = 9;
          normal.family = "FiraCode Nerd Font";
        };
        window = {
          opacity = 0.85;
          decorations = "None";
        };
      };
    };
  };
}
