{
  config,
  lib,
  pkgs,
  ...
}: {
  config = let
    publicDomainName =
      if config.my.modules.nextcloud.stage == "production"
      then "collabora.ritter.family"
      else "collabora-test.ritter.family";
  in
    lib.mkIf config.services.nextcloud.enable {
      # See https://collabora-online-for-nextcloud.readthedocs.io/en/latest/install/
      services.nextcloud = {
        extraApps = {
          inherit (config.services.nextcloud.package.packages.apps) richdocuments;
        };
      };

      virtualisation.oci-containers = lib.mkIf config.services.nextcloud.enable {
        backend = "docker";
        containers = {
          collabora-code = {
            image = "collabora/code:24.04.7.2.1";
            ports = ["9980:9980"];
            environment = {
              extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
            };
            extraOptions = ["--cap-add=MKNOD"];
          };
        };
      };

      systemd.services.nginx = let
        homelabCfg = config.my.homelab.${config.my.host.name};
        occ = "${config.services.nextcloud.occ}/bin/nextcloud-occ";
        postStart = pkgs.writeShellScriptBin "nextcloud-declarative-config" ''
          set -euo pipefail
          CONTAINER_IP=`${pkgs.docker}/bin/docker container inspect -f '{{ .NetworkSettings.IPAddress }}' collabora-code`
          ${occ} config:app:set --value "https://${publicDomainName}" richdocuments wopi_url
          ${occ} config:app:set --value "$CONTAINER_IP,${config.my.homelab.directions.ip},${homelabCfg.ip}" richdocuments wopi_allowlist
        '';
      in {
        after = ["docker-collabora-code.service"];
        requires = ["docker-collabora-code.service"];
        serviceConfig.ExecStartPost = "+${postStart}/bin/nextcloud-declarative-config";
      };

      my.modules.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "collabora.${config.my.host.name}.ritter.family";
            aliases = [publicDomainName];
            target = "http://localhost:9980";
            proxyWebsockets = true;
          }
        ];
      };
    };
}
