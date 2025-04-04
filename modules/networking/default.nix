{
  config,
  lib,
  home-lab,
  ...
}:
let
  cfg = config.my.modules.networking;
  hostCfg = config.my.host;
  homelabCfg =
    if (builtins.hasAttr "${hostCfg.name}" home-lab.hosts) then
      home-lab.hosts.${hostCfg.name}
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
      // (lib.optionalAttrs (homelabCfg != null && (builtins.hasAttr "ip" homelabCfg)) {
        usePredictableInterfaceNames = false;
        interfaces.eth0.ipv4.addresses = [
          {
            address = homelabCfg.ip;
            prefixLength = 24;
          }
        ];
        defaultGateway = home-lab.devices.fritz-box.ip;
        nameservers = [ home-lab.hosts.directions.ip ];
      });
  };
}
