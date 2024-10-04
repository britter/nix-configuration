{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.dyndns;
in {
  options.my.modules.dyndns = {
    enable = lib.mkEnableOption "dyndns";
  };
  config = lib.mkIf cfg.enable {
    sops.secrets."dyndns/server-username".owner = "fritzbox-cloudflare-dyndns";
    sops.secrets."dyndns/server-password".owner = "fritzbox-cloudflare-dyndns";
    sops.secrets.dyndns-cloudflare-api-token = {
      owner = "fritzbox-cloudflare-dyndns";
      key = "acme/cloudflare-dns-api-token";
    };
    sops.templates."fritzbox-cloudflare-dyndns.env" = {
      owner = "fritzbox-cloudflare-dyndns";
      content = ''
        DYNDNS_SERVER_BIND=8000
        DYNDNS_SERVER_USERNAME=${config.sops.placeholder."dyndns/server-username"}
        DYNDNS_SERVER_PASSWORD=${config.sops.placeholder."dyndns/server-password"}
        CLOUDFLARE_API_TOKEN=${config.sops.placeholder.dyndns-cloudflare-api-token}
        CLOUDFLARE_ZONES_IPV4=nextcloud.ritter.family,collabora.ritter.family,nextcloud-test.ritter.family,collabora-test.ritter.family
      '';
    };
    services.fritzbox-cloudflare-dyndns = {
      enable = true;
      environmentFile = config.sops.templates."fritzbox-cloudflare-dyndns.env".path;
    };
    my.modules.https-proxy = {
      enable = true;
      configurations = [
        {
          fqdn = "dyndns.srv-prod-1.ritter.family";
          target = "http://localhost:8000";
        }
      ];
    };
  };
}
