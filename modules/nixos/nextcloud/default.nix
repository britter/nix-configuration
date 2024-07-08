{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.modules.nextcloud;
in {
  options.my.modules.nextcloud = {
    enable = lib.mkEnableOption "nextcloud";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."nextcloud/admin-pass" = {
      owner = "nextcloud";
    };

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud29;
      hostName = "nextcloud.ritter.family";
      config = {
        adminpassFile = config.sops.secrets."nextcloud/admin-pass".path;
      };
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps) bookmarks calendar contacts richdocuments;
        news = pkgs.fetchNextcloudApp {
          url = "https://github.com/nextcloud/news/releases/download/25.0.0-alpha8/news.tar.gz";
          sha256 = "sha256-AhTZGQCLeNgsRBF5w3+Lf9JtNN4D1QncB5t+odU+XUc=";
          license = "agpl3Plus";
        };
        richdocumentscode = pkgs.fetchNextcloudApp {
          url = "https://github.com/CollaboraOnline/richdocumentscode/releases/download/24.4.402/richdocumentscode.tar.gz";
          sha256 = "sha256-H3Wk99DJ+ePZo583y0p7CoIyB8TgZArioNmPWkLvO6s=";
          license = "asl20";
        };
      };
      extraAppsEnable = true;
    };

    services.nginx.virtualHosts."nextcloud.ritter.family" = {
      useACMEHost = "nextcloud.ritter.family";
      forceSSL = true;
    };

    security.acme.certs."nextcloud.ritter.family" = {};

    networking = {
      firewall = {
        allowedTCPPorts = [80 443];
      };
    };
  };
}
