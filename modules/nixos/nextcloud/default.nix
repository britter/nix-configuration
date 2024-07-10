{
  config,
  lib,
  pkgs,
  inputs,
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

    sops.secrets."postgresql/nextcloud-user-password" = {
      restartUnits = ["nginx.service"];
      sopsFile = "${toString inputs.self}/systems/_shared-secrets/warehouse/cyberoffice-secrets.yaml";
    };

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud29;
      hostName = "nextcloud.ritter.family";
      https = true;
      config = {
        adminpassFile = config.sops.secrets."nextcloud/admin-pass".path;
        dbtype = "pgsql";
        dbpassFile = config.sops.secrets."postgresql/nextcloud-user-password".path;
        dbhost = "${config.my.homelab.warehouse.ip}:5432";
      };
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps) bookmarks calendar contacts richdocuments;
        news = pkgs.fetchNextcloudApp {
          url = "https://github.com/nextcloud/news/releases/download/25.0.0-alpha8/news.tar.gz";
          sha256 = "sha256-AhTZGQCLeNgsRBF5w3+Lf9JtNN4D1QncB5t+odU+XUc=";
          license = "agpl3Plus";
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
