_: {
  flake.modules.nixos.beszel-hub =
    {
      config,
      pkgs,
      ...
    }:
    let
      fqdn = "beszel.${config.networking.hostName}.ritter.family";
      yamlFormat = pkgs.formats.yaml { };
      monitoredHosts = [
        "directions"
        "srv-prod-1"
        "srv-prod-2"
        "srv-prod-3"
        "srv-prod-4"
        "srv-prod-5"
      ];
      configYml = yamlFormat.generate "beszel-config.yml" {
        systems = map (h: {
          name = h;
          host = "${h}.ritter.family";
          port = 45876;
          users = [ config.systemConstants.adminEmail ];
        }) monitoredHosts;
      };
    in
    {
      sops.secrets."beszel/hub-private-key" = { };
      sops.secrets."beszel/hub-admin-password" = { };
      sops.templates."beszel-hub-env".content = ''
        USER_PASSWORD=${config.sops.placeholder."beszel/hub-admin-password"}
      '';

      services.beszel.hub = {
        enable = true;
        environment.USER_EMAIL = config.systemConstants.adminEmail;
        environmentFile = config.sops.templates."beszel-hub-env".path;
      };

      systemd.services.beszel-hub.serviceConfig.LoadCredential = [
        "id_ed25519:${config.sops.secrets."beszel/hub-private-key".path}"
      ];
      systemd.services.beszel-hub.preStart = ''
        install -m 600 "$CREDENTIALS_DIRECTORY/id_ed25519" "$STATE_DIRECTORY/beszel_data/id_ed25519"
        install -m 644 ${configYml} "$STATE_DIRECTORY/config.yml"
      '';

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            inherit fqdn;
            target = "http://localhost:${toString config.services.beszel.hub.port}";
            proxyWebsockets = true;
          }
        ];
      };
    };
}
