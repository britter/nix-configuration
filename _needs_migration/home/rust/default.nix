{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.home.rust;
in
{
  options.my.home.rust = {
    enable = lib.mkEnableOption "default";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.rustc
      pkgs.cargo
    ];
  };
}
