_: {
  flake.modules.nixos.forgejo =
    { config, lib, ... }:
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

      sops.secrets."forgejo/admin-user-password".owner = "forgejo";
      systemd.services.forgejo.preStart =
        let
          adminCmd = "${lib.getExe config.services.forgejo.package} admin user";
          pwd = config.sops.secrets."forgejo/admin-user-password";
          user = "britter"; # Note, Forgejo doesn't allow creation of an account named "admin"
        in
        ''
          ${adminCmd} create --admin --email "root@localhost" --username ${user} --password "$(tr -d '\n' < ${pwd.path})" || true
          ## uncomment this line to change an admin user which was already created
          # ${adminCmd} change-password --username ${user} --password "$(tr -d '\n' < ${pwd.path})" || true
        '';

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "git.${config.networking.hostName}.ritter.family";
            aliases = [ "git.ritter.family" ];
            target = "http://localhost:3000";
            maxBodySize = "512M";
          }
        ];
      };
    };
}
