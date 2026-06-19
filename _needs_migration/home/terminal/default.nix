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
    ./nvim
  ];
  options.my.home.terminal = {
    enable = lib.mkEnableOption "terminal";
  };
  config = lib.mkIf cfg.enable {
    my.home.terminal = {
      git.enable = lib.mkDefault true;
      nvim.enable = true;
    };
  };
}
