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
      hostName = "nextcloud.srv-prod-2.ritter.family";
      https = true;
      config = {
        adminpassFile = config.sops.secrets."nextcloud/admin-pass".path;
        dbtype = "pgsql";
      };
      database.createLocally = true;
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps) bookmarks calendar contacts deck memories notes;
        news = pkgs.fetchNextcloudApp {
          url = "https://github.com/nextcloud/news/releases/download/25.0.0-alpha8/news.tar.gz";
          sha256 = "sha256-AhTZGQCLeNgsRBF5w3+Lf9JtNN4D1QncB5t+odU+XUc=";
          license = "agpl3Plus";
        };
      };
      extraAppsEnable = true;
    };

    services.nginx.virtualHosts."nextcloud.srv-prod-2.ritter.family" = {
      useACMEHost = "nextcloud.srv-prod-2.ritter.family";
      forceSSL = true;
    };

    security.acme.certs."nextcloud.srv-prod-2.ritter.family" = {};

    networking = {
      firewall = {
        allowedTCPPorts = [80 443];
      };
    };
  };
}
