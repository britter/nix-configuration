{
  config,
  lib,
  ...
}:
let
  cfg = config.my.home.terminal;
in
{
  imports = [
    ./fish.nix
    ./git.nix
    ./gpg
    ./nvim
    ./ssh.nix
    ./tmux.nix
    ./tools.nix
  ];
  options.my.home.terminal = {
    enable = lib.mkEnableOption "terminal";
  };
  config = lib.mkIf cfg.enable {
    my.home.terminal = {
      fish.enable = true;
      git.enable = lib.mkDefault true;
      gpg.enable = lib.mkDefault true;
      nvim.enable = true;
      ssh.enable = lib.mkDefault true;
      tmux.enable = true;
      tools.enable = true;
    };
  };
}
