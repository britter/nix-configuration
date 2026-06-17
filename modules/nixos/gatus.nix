_: {
  flake.modules.nixos.gatus =
    { config, ... }:
    {
      sops.secrets."gatus/environment" = { };

      services.gatus = {
        enable = true;
        environmentFile = config.sops.secrets."gatus/environment".path;
        settings = {
          web.port = 8888;
          endpoints = [
            {
              name = "NextCloud";
              url = "https://nextcloud.ritter.family/status.php";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
                "[BODY].installed == true"
              ];
            }
            {
              name = "Immich";
              url = "https://photos.ritter.family/api/server/ping";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
                "[BODY].res == pong"
              ];
            }
            {
              name = "Navidrome";
              url = "https://music.ritter.family/ping";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
            }
            {
              name = "Calibre-Web";
              url = "https://books.ritter.family";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
            }
            {
              name = "AdGuard Home";
              url = "https://adguard.ritter.family";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
            }
            {
              name = "Stirling PDF";
              url = "https://pdf.ritter.family";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
            }
          ];
        };
      };

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "status.ritter.family";
            target = "http://localhost:${toString config.services.gatus.settings.web.port}";
          }
        ];
      };
    };
}
