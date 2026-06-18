_: {
  flake.modules.nixos.nextcloud =
    { config, pkgs, ... }:
    {
      sops.secrets."nextcloud/admin-pass" = {
        owner = "nextcloud";
      };

      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud33;
        hostName = "nextcloud.${config.networking.hostName}.ritter.family";
        https = true;
        config = {
          adminpassFile = config.sops.secrets."nextcloud/admin-pass".path;
          dbtype = "pgsql";
        };
        settings = {
          trusted_domains = [ "nextcloud.ritter.family" ];
          trusted_proxies = [ config.home-lab.hosts.directions.ip ];
          default_language = "de";
          default_locale = "de_DE";
          reduce_to_languages = [
            "en"
            "de"
          ];
          default_phone_region = "DE";
          default_timezone = "Europe/Berlin";
          enabledPreviewProviders = [
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

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "nextcloud.${config.networking.hostName}.ritter.family";
            aliases = [ "nextcloud.ritter.family" ];
          }
        ];
      };
    };
}
