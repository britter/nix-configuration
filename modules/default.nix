{config, ...}: let
  cfg = config.my.host;
in {
  imports = [
    ./1password
    ./adguard
    ./common/options
    ./common/utilities
    ./disko
    ./fonts
    ./gaming
    ./gnome
    ./i18n
    ./my-user
    ./networking
    ./nix
    ./sound
    ./ssh-access
  ];

  config = {
    my.modules = {
      # enabled only on desktops
      _1password.enable = cfg.role == "desktop";
      gnome.enable = cfg.role == "desktop";
      sound.enable = cfg.role == "desktop";
      my-user.enable = cfg.role == "desktop";

      # enabled only on private desktops
      gaming.enable = cfg.role == "desktop" && (builtins.elem "private" cfg.profiles);

      # enabled only on servers
      ssh-access.enable = cfg.role == "server";

      # enabled on all machines by default
      fonts.enable = true;
      i18n.enable = true;
      networking.enable = true;
    };
  };
}
