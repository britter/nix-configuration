{config, ...}: let
  cfg = config.my.host;
in {
  imports = [
    ./acme
    ./adguard
    ./comin
    ./disko
    ./fonts
    ./gaming
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
    ./utilities
    ./vaultwarden
  ];

  config = {
    my.modules = {
      # enabled only on desktops
      fonts.enable = cfg.role == "desktop";
      my-user.enable = cfg.role == "desktop";
      sound.enable = cfg.role == "desktop";
      sway.enable = cfg.role == "desktop";
      gaming.enable = cfg.role == "desktop";

      # enabled only on servers
      comin.enable = cfg.role == "server";
      monitoring.enable = cfg.role == "server";
      sops.enable = cfg.role == "server";
      ssh-access.enable = cfg.role == "server";

      # enabled on all machines by default
      i18n.enable = true;
      networking.enable = true;
    };
  };
}
