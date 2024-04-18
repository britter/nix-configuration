{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.modules.networking;
  hostName = config.my.hostName;
in {
  options.my.modules.networking = {
    enable = lib.mkEnableOption "networking";
  };
  options.my.hostName = lib.mkOption {
    type = lib.types.str;
  };

  config = lib.mkIf cfg.enable {
    networking = {
      inherit hostName;
      networkmanager.enable = true;
    };
  };
}
