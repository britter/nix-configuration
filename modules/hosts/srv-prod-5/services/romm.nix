{ config, ... }:
let
  inherit (config.flake.modules.nixos) romm;
in
{
  flake.modules.nixos.romm-on-srv-prod-5 =
    { config, ... }:
    {
      imports = [ romm ];

      sops.secrets."romm/auth-secret-key" = { };

      sops.templates."romm.env" = {
        owner = "romm";
        content = ''
          ROMM_AUTH_SECRET_KEY=${config.sops.placeholder."romm/auth-secret-key"}
        '';
      };

      services.romm = {
        enable = true;
        environmentFiles = [
          config.sops.templates."romm.env".path
        ];
        # The romm module sets up the nginx virtualHost (root, /api, /ws,
        # /netplay). https-proxy adds ACME + TLS on the same hostName via
        # attribute-set merging.
        nginx = {
          enable = true;
          hostName = "roms.srv-prod-5.ritter.family";
        };
      };

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "roms.srv-prod-5.ritter.family";
            aliases = [ "roms.ritter.family" ];
            target = null;
          }
        ];
      };

      fileSystems."/var/lib/romm/library" = {
        fsType = "nfs";
        device = "storage.ritter.family:/mnt/default-pool/romm-library";
      };
      systemd.services.romm-api.unitConfig.RequiresMountsFor = "/var/lib/romm/library";
      systemd.services.romm-worker.unitConfig.RequiresMountsFor = "/var/lib/romm/library";
    };
}
