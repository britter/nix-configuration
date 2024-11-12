{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.https-proxy;
  proxyConfig = lib.types.submodule (_: {
    options = {
      fqdn = lib.mkOption {
        type = lib.types.str;
      };
      aliases = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };
      target = lib.mkOption {
        type = lib.types.str;
      };
      proxyWebsockets = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  });
in {
  options.my.modules.https-proxy = {
    enable = lib.mkEnableOption "https-proxy";
    configurations = lib.mkOption {
      type = lib.types.listOf proxyConfig;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [80 443];

    services.nginx.enable = true;
    services.nginx.virtualHosts = let
      makeHost = conf: {
        ${conf.fqdn} = {
          serverAliases = conf.aliases;
          useACMEHost = conf.fqdn;
          forceSSL = true;
          locations."/" = {
            inherit (conf) proxyWebsockets;
            recommendedProxySettings = true;
            proxyPass = conf.target;
          };
        };
      };
    in
      lib.mkMerge (lib.map makeHost
        cfg.configurations);

    my.modules.acme.enable = true;
    security.acme.certs = let
      makeCert = conf: {
        ${conf.fqdn} = {};
      };
    in
      lib.mkMerge (lib.map makeCert
        cfg.configurations);
  };
}
