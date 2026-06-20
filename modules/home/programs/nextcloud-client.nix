_: {
  flake.modules.nixos.nextcloud-client = {
    # nextcloud-client uses gnome-keyring (gated by polkit) to persist
    # its authentication data across reboots
    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;
  };

  flake.modules.homeManager.nextcloud-client = {
    services.nextcloud-client.enable = true;
  };
}
