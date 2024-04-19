{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.terminal;
in {
  imports = [
    ./bat.nix
    ./btop.nix
    ./fish.nix
    ./tmux.nix
    ./tools.nix
  ];
  options.my.home.terminal = {
    enable = lib.mkEnableOption "terminal";
  };
  config = lib.mkIf cfg.enable {
    my.home.terminal = {
      bat.enable = true;
      btop.enable = true;
      fish.enable = true;
      tmux.enable = true;
      tools.enable = true;
    };
  };
}
