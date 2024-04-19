{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.modules.networking;
  hostCfg = config.my.host;
in {
  options.my.modules.networking = {
    enable = lib.mkEnableOption "networking";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      hostName = hostCfg.name;
      networkmanager.enable = hostCfg.role == "desktop";
    };
  };
}
