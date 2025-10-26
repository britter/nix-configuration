{
  config,
  lib,
  pkgs,
  home-lab,
  ...
}:
let
  cfg = config.my.modules.nextcloud;
in
{
  imports = [
    ./memories.nix
    ./richdocuments.nix
  ];

  options.my.modules.nextcloud = {
    enable = lib.mkEnableOption "nextcloud";
    stage = lib.mkOption {
      type = lib.types.enum [
        "test"
        "production"
      ];
      default = "test";
    };
    publicDomainName = lib.mkOption {
      type = lib.types.str;
      default =
        if config.my.modules.nextcloud.stage == "production" then
          "nextcloud.ritter.family"
        else
          "nextcloud-test.ritter.family";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."nextcloud/admin-pass" = {
      owner = "nextcloud";
    };

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud32;
      hostName = "nextcloud.${config.my.host.name}.ritter.family";
      https = true;
      config = {
        adminpassFile = config.sops.secrets."nextcloud/admin-pass".path;
        dbtype = "pgsql";
      };
      settings = {
        trusted_domains = [ cfg.publicDomainName ];
        trusted_proxies = [ home-lab.hosts.directions.ip ];
        default_language = "de";
        default_locale = "de_DE";
        reduce_to_languages = [
          "en"
          "de"
        ];
        default_phone_region = "DE";
        default_timezone = "Europe/Berlin";
        enabledPreviewProviders = [
          # Default providers according to https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html#enabledpreviewproviders
          "OC\\Preview\\BMP"
          "OC\\Preview\\GIF"
          "OC\\Preview\\JPEG"
          "OC\\Preview\\Krita"
          "OC\\Preview\\MarkDown"
          "OC\\Preview\\MP3"
          "OC\\Preview\\OpenDocument"
          "OC\\Preview\\PNG"
          "OC\\Preview\\TXT"
          "OC\\Preview\\XBitmap"
          # Additional providers
          "OC\\Preview\\HEIC"
        ];
      };
      database.createLocally = true;
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps)
          bookmarks
          calendar
          contacts
          cookbook
          deck
          news
          notes
          ;
      };
      extraAppsEnable = true;
    };

    services.nginx.virtualHosts."nextcloud.${config.my.host.name}.ritter.family" = {
      serverAliases = [ cfg.publicDomainName ];
      useACMEHost = "nextcloud.${config.my.host.name}.ritter.family";
      forceSSL = true;
    };

    my.modules.acme.enable = true;
    security.acme.certs."nextcloud.${config.my.host.name}.ritter.family" = { };

    networking = {
      firewall = {
        allowedTCPPorts = [
          80
          443
        ];
      };
    };
  };
}
