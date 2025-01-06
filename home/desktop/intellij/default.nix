{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop.intellij;
in {
  options.my.home.desktop.intellij = {
    enable = lib.mkEnableOption "intellij";
    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (jetbrains.plugins.addPlugins jetbrains.idea-community-bin cfg.plugins)
    ];
    programs.git.ignores = [
      ## IntelliJ stuff
      ".idea"
      "*.iml"
      "out/"
    ];
  };
}
