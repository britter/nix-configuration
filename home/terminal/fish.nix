{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.terminal.fish;
in {
  options.my.home.terminal.fish = {
    enable = lib.mkEnableOption "fish";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      eza # ls replacement
      tokei # count lines of code
    ];

    programs.starship.enable = true; # prompt framework

    programs.fish = {
      enable = true;

      shellAliases = {
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        "cat" = "bat";
        "ls" = "eza";
        "ll" = "eza -la";
        "loc" = "tokei";
      };

      shellInit = ''
        set -x LANG en_US.utf-8
        set -x MAVEN_OPTS "-Duser.name=benedikt"
        set -x GPG_TTY (tty)
      '';
    };
  };
}
