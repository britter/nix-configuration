{
  config,
  lib,
  ...
}:
let
  cfg = config.my.home.desktop.browser;
in
{
  imports = [
    ./librewolf.nix
  ];
  options.my.home.desktop.browser = {
    enable = lib.mkEnableOption "browser";
  };

  config = lib.mkIf cfg.enable {
    my.home.desktop.browser.librewolf.enable = true;
  };
}
