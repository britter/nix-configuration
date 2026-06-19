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
    ./git.nix
    ./gpg
    ./nvim
  ];
  options.my.home.terminal = {
    enable = lib.mkEnableOption "terminal";
  };
  config = lib.mkIf cfg.enable {
    my.home.terminal = {
      git.enable = lib.mkDefault true;
      gpg.enable = lib.mkDefault true;
      nvim.enable = true;
    };
  };
}
