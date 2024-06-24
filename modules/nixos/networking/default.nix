{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.networking;
  hostCfg = config.my.host;
in {
  options.my.modules.networking = {
    enable = lib.mkEnableOption "networking";
  };

  config = lib.mkIf cfg.enable {
    networking =
      {
        hostName = hostCfg.name;
        networkmanager.enable = hostCfg.role == "desktop";
      }
      // (lib.optionalAttrs (hostCfg.ip != null) {
        usePredictableInterfaceNames = false;
        interfaces.eth0.ipv4.addresses = [
          {
            address = hostCfg.ip;
            prefixLength = 24;
          }
        ];
        defaultGateway = "192.168.178.1";
        nameservers = ["192.168.178.105"];
      });
  };
}
