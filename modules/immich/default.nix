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
      settings.server.externalDomain = "photos.ritter.family";
    };

    my.modules.https-proxy = {
      enable = true;
      configurations = [
        {
          fqdn = "photos.ritter.family";
          target = "http://localhost:2283";
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
