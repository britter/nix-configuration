_: {
  flake.modules.nixos.immich =
    { config, ... }:
    {
      services.immich = {
        enable = true;
        # see https://docs.immich.app/install/config-file
        settings = {
          server.externalDomain = "https://photos.ritter.family";
          storageTemplate.enabled = true;
        };
      };

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "photos.${config.networking.hostName}.ritter.family";
            target = "http://localhost:2283";
            proxyWebsockets = true;
            maxBodySize = "50000M";
            proxyTimeout = "600s";
          }
        ];
      };
    };
}
