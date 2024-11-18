{
  config,
  lib,
  ...
}: let
  cfg = config.my.home.terminal;
in {
  imports = [
    ./bat.nix
    ./btop.nix
    ./direnv.nix
    ./fish.nix
    ./fzf.nix
    ./gh.nix
    ./git.nix
    ./gpg
    ./helix.nix
    ./nvim
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
      git.enable = true;
      gpg.enable = true;
      helix.enable = true;
      nvim.enable = true;
      tmux.enable = true;
      tools.enable = true;
      yazi.enable = true;
    };
  };
}
