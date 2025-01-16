{
  config,
  lib,
  ...
}: let
  cfg = config.my.host;
in {
  imports = [
    ./acme
    ./adguard
    ./app-sync
    ./comin
    ./disko
    ./fonts
    ./gaming
    ./git-server
    ./grafana
    ./homelab
    ./home-manager
    ./homepage
    ./https-proxy
    ./i18n
    ./monitoring
    ./my-user
    ./networking
    ./nextcloud
    ./nix
    ./options
    ./proxmox-vm
    ./sops
    ./sound
    ./ssh-access
    ./sway
    ./system-recovery
    ./utilities
    ./vaultwarden
  ];

  config = {
    my.modules =
      {
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
