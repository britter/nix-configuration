_: {
  flake.modules.nixos.paperless =
    { config, ... }:
    {
      sops.secrets."paperless/admin-password" = { };

      services.paperless = {
        enable = true;
        port = 28981; # default; referenced by the proxy target below
        database.createLocally = true; # use the local postgres already running on this host
        passwordFile = config.sops.secrets."paperless/admin-password".path;
        settings = {
          PAPERLESS_URL = "https://documents.ritter.family"; # required for CSRF/redirects behind proxy
          PAPERLESS_TIME_ZONE = "Europe/Berlin";
          PAPERLESS_OCR_LANGUAGE = "deu+eng"; # nixpkgs module auto-builds tesseract5 with these langs
        };
      };

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "documents.${config.networking.hostName}.ritter.family";
            aliases = [ "documents.ritter.family" ];
            target = "http://localhost:28981";
            maxBodySize = "100M";
          }
        ];
      };
    };
}
