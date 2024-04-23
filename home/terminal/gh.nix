{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.terminal.gh;
in {
  options.my.home.terminal.gh = {
    enable = lib.mkEnableOption "gh";
  };

  config = lib.mkIf cfg.enable {
    programs.gh = {
      enable = true;

      extensions = [pkgs.gh-get];

      settings = {
        git_protocol = "ssh";
      };
    };
  };
}
