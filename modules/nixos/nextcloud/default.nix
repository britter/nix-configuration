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
        inherit (config.services.nextcloud.package.packages.apps) bookmarks calendar contacts cookbook deck memories richdocuments;
        news = pkgs.fetchNextcloudApp {
          url = "https://github.com/nextcloud/news/releases/download/25.0.0-alpha7/news.tar.gz";
          sha256 = "sha256-XNGjf7SWgJYFdVNOh3ED0jxSG0GJwWImVQq4cJT1Lo4=";
          license = "agpl3Plus";
        };
      };
      extraAppsEnable = true;
    };

    services.nginx.virtualHosts."nextcloud.ritter.family" = {
      useACMEHost = "nextcloud.ritter.family";
      forceSSL = true;
    };

    users.users.nginx.extraGroups = ["acme"];

    sops.secrets."acme/cloudflare-dns-api-token" = {};
    sops.templates."acme-cloudflare-dns-api-token.env".content = ''
      CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."acme/cloudflare-dns-api-token"}
    '';

    security.acme = {
      acceptTerms = true;
      defaults.email = "beneritter@gmail.com";

      certs."nextcloud.ritter.family" = {
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        credentialsFile = config.sops.templates."acme-cloudflare-dns-api-token.env".path;
      };
    };

    networking = {
      firewall = {
        allowedTCPPorts = [80 443];
      };
    };
  };
}
