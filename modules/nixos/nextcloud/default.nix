{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.modules.nextcloud;
in {
  imports = [
    ./memories.nix
    ./richdocuments.nix
  ];

  options.my.modules.nextcloud = {
    enable = lib.mkEnableOption "nextcloud";
    stage = lib.mkOption {
      type = lib.types.enum ["test" "production"];
    };
    publicDomainName = lib.mkOption {
      type = lib.types.str;
      default =
        if config.my.modules.nextcloud.stage == "production"
        then "nextcloud.ritter.family"
        else "nextcloud-test.ritter.family";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."nextcloud/admin-pass" = {
      owner = "nextcloud";
    };

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud29;
      hostName = "nextcloud.${config.my.host.name}.ritter.family";
      https = true;
      config = {
        adminpassFile = config.sops.secrets."nextcloud/admin-pass".path;
        dbtype = "pgsql";
      };
      settings = {
        trusted_domains = [cfg.publicDomainName];
        trusted_proxies = [config.my.homelab.directions.ip];
        default_language = "de";
        default_locale = "de_DE";
        reduce_to_languages = ["en" "de"];
        default_phone_region = "DE";
        default_timezone = "Europe/Berlin";
      };
      database.createLocally = true;
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps) bookmarks calendar contacts cookbook deck notes;
        news = pkgs.fetchNextcloudApp {
          url = "https://github.com/nextcloud/news/releases/download/25.0.0-alpha12/news.tar.gz";
          sha256 = "sha256-pnvyMZQ+NYMgH0Unfh5S19HdZSjnghgoUDAoi2KIXNI=";
          license = "agpl3Plus";
        };
        integration_google = pkgs.fetchNextcloudApp {
          url = "https://github.com/nextcloud-releases/integration_google/releases/download/v3.1.0/integration_google-v3.1.0.tar.gz";
          sha256 = "sha256-tqsi95+CIoHRFvv8I0HoVl5hjhROrr9epWvNeDynMXQ=";
          license = "agpl3Plus";
        };
      };
      extraAppsEnable = true;
    };

    services.nginx.virtualHosts."nextcloud.${config.my.host.name}.ritter.family" = {
      serverAliases = [cfg.publicDomainName];
      useACMEHost = "nextcloud.${config.my.host.name}.ritter.family";
      forceSSL = true;
    };

    my.modules.acme.enable = true;
    security.acme.certs."nextcloud.${config.my.host.name}.ritter.family" = {};

    networking = {
      firewall = {
        allowedTCPPorts = [80 443];
      };
    };
  };
}
