{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.immich;
in
{
  options.my.modules.immich = {
    enable = lib.mkEnableOption "immich";
  };

  config = lib.mkIf cfg.enable {
    services.immich = {
      enable = true;
      # see https://docs.immich.app/install/config-file
      settings = {
        server.externalDomain = "https://photos.ritter.family";
        storageTemplate.enabled = true;
      };
    };

    my.modules.https-proxy = {
      enable = true;
      configurations = [
        {
          fqdn = "photos.${config.my.host.name}.ritter.family";
          target = "http://localhost:2283";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 50000M;
            proxy_read_timeout   600s;
            proxy_send_timeout   600s;
            send_timeout         600s;
          '';
        }
      ];
    };
  };
}
