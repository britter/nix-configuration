_: {
  flake.modules.nixos.uptime-kuma =
    { config, ... }:
    {
      sops.secrets."uptime-kuma/db-key" = {
        owner = "uptime-kuma";
      };
      sops.templates."uptime-kuma.env" = {
        owner = "uptime-kuma";
        content = ''
          UPTIME_KUMA_DB_KEY=${config.sops.placeholder."uptime-kuma/db-key"}
        '';
      };

      services.uptime-kuma = {
        enable = true;
        settings = {
          HOST = "127.0.0.1";
          PORT = "3001";
        };
      };

      systemd.services.uptime-kuma.serviceConfig.EnvironmentFile =
        config.sops.templates."uptime-kuma.env".path;

      # Monitors to configure via the web UI at https://status.ritter.family:
      # - Nextcloud:    https://nextcloud.ritter.family
      # - Immich:       https://photos.ritter.family
      # - Navidrome:    https://music.ritter.family
      # - Calibre-Web:  https://books.ritter.family
      # - AdGuard Home: https://adguard.ritter.family
      # - Stirling PDF: https://pdf.ritter.family

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "status.ritter.family";
            target = "http://localhost:3001";
            proxyWebsockets = true;
          }
        ];
      };
    };
}
