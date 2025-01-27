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

  config = let
    idea = pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.idea-community-bin cfg.plugins;
    ideaStartScript = pkgs.writeShellApplication {
      name = "idea";
      text = ''
        DIR=''${1:-$(pwd)}
        nohup ${lib.getExe idea} "$DIR" > /dev/null 2>&1 &
      '';
    };
  in
    lib.mkIf cfg.enable {
      home.packages = [
        idea
        ideaStartScript
      ];
      programs.git.ignores = [
        ## IntelliJ stuff
        ".idea"
        "*.iml"
        "out/"
      ];
    };
}
