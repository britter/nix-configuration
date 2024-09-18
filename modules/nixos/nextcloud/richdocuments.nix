{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services.nextcloud.enable {
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

    systemd.services.nginx = {
      after = ["docker-collabora-code.service"];
      requires = ["docker-collabora-code.service"];
    };

    my.modules.https-proxy = {
      enable = true;
      configurations = [
        {
          fqdn = "collabora.${config.my.host.name}.ritter.family";
          target = "http://localhost:9980";
          proxyWebsockets = true;
        }
      ];
    };
  };
}
