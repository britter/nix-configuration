{ config, ... }:
let
  inherit (config.flake.modules.nixos) forgejo;
  restic = import ../../srv-prod-2/services/_restic-constants.nix;
in
{
  flake.modules.nixos.forgejo-on-srv-prod-6 =
    { config, ... }:
    {
      imports = [ forgejo ];

      sops.secrets."restic/forgejo/repository-password" = { };
      sops.secrets."restic/forgejo/garage-access-key-id" = { };
      sops.secrets."restic/forgejo/garage-secret-access-key" = { };
      sops.templates."restic/forgejo/secrets.env" = {
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic/forgejo/garage-access-key-id"}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic/forgejo/garage-secret-access-key"}
          RESTIC_PASSWORD=${config.sops.placeholder."restic/forgejo/repository-password"}
        '';
      };

      services.restic.backups.forgejo = {
        environmentFile = config.sops.templates."restic/forgejo/secrets.env".path;
        paths = [ "/var/lib/forgejo" ];
        repository = "${restic.bucket-prefix}-forgejo";
        initialize = true;
        inherit (restic) pruneOpts timerConfig;
      };
    };
}
