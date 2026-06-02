{
  config,
  lib,
  ...
}:
let
  cfg = config.my.host;
in
{
  imports = [
    ./acme
    ./adguard
    ./calibre-web
    ./comin
    ./dirty-frag-fix
    ./fonts
    ./gaming
    ./git-server
    ./grafana
    ./home-manager
    ./homepage
    ./https-proxy
    ./immich
    ./minio
    ./monitoring
    ./my-user
    ./navidrome
    ./nextcloud
    ./nix
    ./options
    ./proxmox-vm
    ./restic-restore
    ./sops
    ./sound
    ./ssh-access
    ./stirling-pdf
    ./sway
    ./system-recovery
    ./tailscale
    ./vaultwarden
  ];

  config = {
    my.modules =
      lib.optionalAttrs (cfg.role == "desktop") {
        fonts.enable = true;
        gaming.enable = true;
        my-user.enable = true;
        sound.enable = true;
        sway.enable = true;
        system-recovery.enable = true;
      }
      // lib.optionalAttrs (cfg.role == "server") {
        comin.enable = true;
        sops.enable = true;
        ssh-access.enable = true;
      };
  };
}
