_: {
  flake.modules.nixos.forgejo =
    { config, ... }:
    {
      services.forgejo = {
        enable = true;
        database.type = "sqlite3";
        settings = {
          server = {
            DOMAIN = "git.ritter.family";
            ROOT_URL = "https://git.ritter.family/";
            HTTP_ADDR = "127.0.0.1";
            HTTP_PORT = 3000;
            DISABLE_SSH = true;
          };
          service.DISABLE_REGISTRATION = true;
        };
      };

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "git.${config.networking.hostName}.ritter.family";
            aliases = [ "git.ritter.family" ];
            target = "http://localhost:3000";
            extraConfig = ''
              client_max_body_size 512M;
            '';
          }
        ];
      };
    };
}
