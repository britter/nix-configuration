_: {
  flake.modules.nixos.nextcloud =
    { config, pkgs, ... }:
    {
      # nixpkgs removed services.nextcloud.config.adminpassFile (PR:
      # https://github.com/NixOS/nixpkgs/pull/571775): the option was
      # only evaluated on first-time install and had no effect afterwards. The
      # admin user already exists in the database. To set an admin password
      # going forward, use:
      #   nextcloud-occ user:resetpassword <admin-user>
      # (to create additional admin users: nextcloud-occ user:add <user> and
      #   nextcloud-occ group:adduser admin <user>)
      sops.secrets."nextcloud/admin-pass" = {
        owner = "nextcloud";
      };

      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud35;
        hostName = "nextcloud.${config.networking.hostName}.ritter.family";
        https = true;
        config = {
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
            pantry
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
