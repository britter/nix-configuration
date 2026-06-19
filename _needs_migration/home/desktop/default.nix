{
  config,
  lib,
  ...
}:
let
  cfg = config.my.home.desktop;
in
{
  imports = [ ];

  options.my.home.desktop = {
    enable = lib.mkEnableOption "desktop";
  };

  config = lib.mkIf cfg.enable {
    catppuccin = {
      cursors = {
        enable = true;
        accent = "dark";
      };
      librewolf.profiles.default.enable = false;
    };
  };
}
