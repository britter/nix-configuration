{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop.joplin;
in {
  options.my.home.desktop.joplin = {
    enable = lib.mkEnableOption "joplin";
  };

  config = lib.mkIf cfg.enable {
    programs.joplin-desktop.enable = true;
  };
}
