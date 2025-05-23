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
    ./bat.nix
    ./btop.nix
    ./direnv.nix
    ./fish.nix
    ./fzf.nix
    ./gh.nix
    ./git.nix
    ./gpg
    ./nvim
    ./ssh.nix
    ./tmux.nix
    ./tools.nix
    ./yazi.nix
  ];
  options.my.home.terminal = {
    enable = lib.mkEnableOption "terminal";
  };
  config = lib.mkIf cfg.enable {
    my.home.terminal = {
      bat.enable = true;
      btop.enable = true;
      direnv.enable = true;
      fish.enable = true;
      fzf.enable = true;
      gh.enable = true;
      git.enable = lib.mkDefault true;
      gpg.enable = lib.mkDefault true;
      nvim.enable = true;
      ssh.enable = lib.mkDefault true;
      tmux.enable = true;
      tools.enable = true;
      yazi.enable = true;
    };
  };
}
