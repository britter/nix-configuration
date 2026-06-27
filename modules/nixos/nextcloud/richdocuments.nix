_: {
  flake.modules.nixos.nextcloud =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      publicDomainName = "collabora.ritter.family";
    in
    lib.mkIf config.services.nextcloud.enable {
      services.nextcloud.extraApps = {
        inherit (config.services.nextcloud.package.packages.apps) richdocuments;
      };

      virtualisation.oci-containers = {
        backend = "docker";
        containers = {
          collabora-code = {
            image = "collabora/code:25.04.6.2.1";
            ports = [ "9980:9980" ];
            environment = {
              extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
              domain = "nextcloud.${config.networking.hostName}.ritter.family";
            };
            extraOptions = [ "--cap-add=MKNOD" ];
          };
        };
      };

      systemd.services.nextcloud-richdocuments-config =
        let
          homelabCfg = config.home-lab.hosts.${config.networking.hostName};
          occ = lib.getExe config.services.nextcloud.occ;
          deps = [
            "docker-collabora-code.service"
            "nextcloud-setup.service"
          ];
        in
        {
          after = deps;
          requires = deps;
          wantedBy = [ "multi-user.target" ];
          script = ''
            set -euo pipefail
            CONTAINER_IP=`${pkgs.docker}/bin/docker container inspect -f '{{ .NetworkSettings.Networks.bridge.IPAddress }}' collabora-code`
            ${occ} config:app:set --value "https://${publicDomainName}" richdocuments wopi_url
            ${occ} config:app:set --value "$CONTAINER_IP:9980,${config.home-lab.hosts.directions.ip},${homelabCfg.ip},100.94.107.46" richdocuments wopi_allowlist
          '';
          serviceConfig.Type = "oneshot";
        };

      services.https-proxy.configurations = [
        {
          fqdn = "collabora.${config.networking.hostName}.ritter.family";
          aliases = [ publicDomainName ];
          target = "http://localhost:9980";
          proxyWebsockets = true;
        }
      ];
    };
}
