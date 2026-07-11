_: {
  flake.modules.nixos.it-tools =
    { config, pkgs, ... }:
    let
      fqdn = "tools.${config.networking.hostName}.ritter.family";
    in
    {
      services.https-proxy = {
        enable = true;
        # alias so the edge proxy's preserved Host header (tools.ritter.family)
        # matches here; without it the request falls through to the default vhost
        # (forgejo) since srv-prod-6 hosts more than one vhost. target null → TLS vhost only.
        configurations = [
          {
            inherit fqdn;
            aliases = [ "tools.ritter.family" ];
          }
        ];
      };

      services.nginx.virtualHosts.${fqdn} = {
        root = "${pkgs.it-tools}/lib";
        # SPA: vue-router history mode → fall back to index.html for deep links
        locations."/".tryFiles = "$uri $uri/ /index.html";
      };
    };
}
