{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.networking;
  hostCfg = config.my.host;
  homelabCfg =
    if (builtins.hasAttr "${hostCfg.name}" config.my.homelab) then
      config.my.homelab.${hostCfg.name}
    else
      null;
in
{
  options.my.modules.networking = {
    enable = lib.mkEnableOption "networking";
  };

  config = lib.mkIf cfg.enable {
    networking =
      {
        hostName = hostCfg.name;
        networkmanager.enable = hostCfg.role == "desktop";
      }
      // (lib.optionalAttrs (homelabCfg != null) {
        usePredictableInterfaceNames = false;
        interfaces.eth0.ipv4.addresses = [
          {
            address = homelabCfg.ip;
            prefixLength = 24;
          }
        ];
        defaultGateway = config.my.homelab.fritz-box.ip;
        nameservers = [ config.my.homelab.directions.ip ];
      });
  };
}
