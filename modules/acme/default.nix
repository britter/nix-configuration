{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.acme;
in
{
  options.my.modules.acme = {
    enable = lib.mkEnableOption "acme";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."acme/cloudflare-dns-api-token" = { };

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "beneritter@gmail.com";
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        credentialFiles = {
          "CLOUDFLARE_DNS_API_TOKEN_FILE" = config.sops.secrets."acme/cloudflare-dns-api-token".path;
        };
      };
    };
    users.users.nginx.extraGroups = [ "acme" ];
  };
}
