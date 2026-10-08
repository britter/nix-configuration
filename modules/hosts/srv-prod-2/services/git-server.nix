{ config, ... }:
let
  inherit (config.flake.modules.nixos) git-server;
  restic = import ./_restic-constants.nix;
in
{
  flake.modules.nixos.git-server-on-srv-prod-2 =
    { config, ... }:
    {
      imports = [ git-server ];

      systemd.tmpfiles.rules = [
        "d /var/backups 0777 root root"
      ];

      sops.secrets."restic/git/repository-password" = { };
      sops.secrets."restic/git/garage-access-key-id" = { };
      sops.secrets."restic/git/garage-secret-access-key" = { };
      sops.templates."restic/git/secrets.env" = {
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic/git/garage-access-key-id"}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic/git/garage-secret-access-key"}
          RESTIC_PASSWORD=${config.sops.placeholder."restic/git/repository-password"}
        '';
      };

      services.restic.backups.git = {
        environmentFile = config.sops.templates."restic/git/secrets.env".path;
        paths = [ "/srv/git" ];
        repository = "${restic.bucket-prefix}-git";
        initialize = true;
        inherit (restic) pruneOpts timerConfig;
      };
    };
}
