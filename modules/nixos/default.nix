{config, ...}: let
  cfg = config.my.host;
in {
  imports = [
    ../common
    ./1password
    ./acme
    ./adguard
    ./comin
    ./disko
    ./fonts
    ./gaming
    ./grafana
    ./homelab
    ./homepage
    ./https-proxy
    ./i18n
    ./monitoring
    ./my-user
    ./networking
    ./nextcloud
    ./nix
    ./proxmox-vm
    ./sops
    ./sound
    ./ssh-access
    ./sway
  ];

  config = {
    my.modules = {
      # enabled only on desktops
      _1password.enable = cfg.role == "desktop";
      fonts.enable = cfg.role == "desktop";
      my-user.enable = cfg.role == "desktop";
      sound.enable = cfg.role == "desktop";
      sway.enable = cfg.role == "desktop";

      # enabled only on private desktops
      gaming.enable = cfg.role == "desktop" && (builtins.elem "private" cfg.profiles);

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
