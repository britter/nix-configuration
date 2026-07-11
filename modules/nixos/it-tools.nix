_: {
  flake.modules.nixos.it-tools =
    { config, pkgs, ... }:
    let
      fqdn = "tools.${config.networking.hostName}.ritter.family";
    in
    {
      services.https-proxy = {
        enable = true;
        configurations = [ { inherit fqdn; } ]; # target null → TLS vhost only
      };

      services.nginx.virtualHosts.${fqdn} = {
        root = "${pkgs.it-tools}/lib";
        # SPA: vue-router history mode → fall back to index.html for deep links
        locations."/".tryFiles = "$uri $uri/ /index.html";
      };
    };
}
