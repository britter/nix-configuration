_: {
  flake.modules.nixos.nextcloud =
    {
      config,
      lib,
      ...
    }:
    let
      publicDomainName = "collabora.ritter.family";
    in
    lib.mkIf config.services.nextcloud.enable {
      services.nextcloud.extraApps = {
        inherit (config.services.nextcloud.package.packages.apps) richdocuments;
      };

      services.collabora-online = {
        enable = true;
        port = 9980; # default; kept explicit to match the https-proxy target
        settings = {
          ssl.enable = false; # nginx terminates TLS
          ssl.termination = true;
          net.listen = "loopback";
          net.post_allow.host = [
            "127.0.0.1"
            "::1"
          ];
          storage.wopi = {
            "@allow" = true;
            host = [ "nextcloud.ritter.family" ]; # WOPISrc host coolwsd will accept
          };
          server_name = publicDomainName; # avoids reverse-proxy redirect loops
        };
      };

      systemd.services.nextcloud-richdocuments-config =
        let
          homelabCfg = config.home-lab.hosts.${config.networking.hostName};
          occ = lib.getExe config.services.nextcloud.occ;
          deps = [
            "coolwsd.service"
            "nextcloud-setup.service"
          ];
        in
        {
          after = deps;
          requires = deps;
          wantedBy = [ "multi-user.target" ];
          script = ''
            set -euo pipefail
            ${occ} config:app:set --value "https://${publicDomainName}" richdocuments wopi_url
            ${occ} config:app:set --value "127.0.0.1,::1,${config.home-lab.hosts.directions.ip},${homelabCfg.ip}" richdocuments wopi_allowlist
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
