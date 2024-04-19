{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.terminal.tools;
in {
  options.my.home.terminal.tools = {
    enable = lib.mkEnableOption "tools";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      curl
      eza # ls replacement
      file
      httpie
      jq
      mob # smooth git handover
      tokei # count lines of code
      tldr # better man pages
      unzip
      wget
      zip
    ];
    programs.fzf.enable = true; # fuzzy finding
    programs.ripgrep.enable = true; # recursive grep
    programs.zoxide.enable = true; # smart cd replacement
  };
}
