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
    ./disko
    ./fonts
    ./gaming
    ./git-server
    ./grafana
    ./home-manager
    ./homepage
    ./https-proxy
    ./i18n
    ./minio
    ./monitoring
    ./my-user
    ./networking
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
    ./utilities
    ./vaultwarden
  ];

  config = {
    my.modules = {
      i18n.enable = true;
      networking.enable = true;
    }
    // lib.optionalAttrs (cfg.role == "desktop") {
      fonts.enable = true;
      gaming.enable = true;
      my-user.enable = true;
      sound.enable = true;
      sway.enable = true;
      system-recovery.enable = true;
    }
    // lib.optionalAttrs (cfg.role == "server") {
      comin.enable = true;
      monitoring.enable = true;
      sops.enable = true;
      ssh-access.enable = true;
    };
  };
}
