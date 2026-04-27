{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.my.home.desktop.sway.noctalia-shell;
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];
  options.my.home.desktop.sway.noctalia-shell = {
    enable = lib.mkEnableOption "noctalia";
  };

  config = lib.mkIf cfg.enable {
    programs.noctalia-shell.enable = true;
    home.file.".cache/noctalia/wallpapers.json" = {
      text = builtins.toJSON {
        defaultWallpaper = "${config.my.home.desktop.wallpapers.evening-sky}";
      };
    };
  };
}
