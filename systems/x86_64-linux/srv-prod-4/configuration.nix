{
  ...
}:
{
  imports = [
    ../../../modules
    ./disko-config.nix
  ];

  my = {
    host = {
      role = "server";
    };
    modules = {
      proxmox-vm.enable = true;
      immich.enable = true;
      tailscale.enable = true;
    };
  };

  boot.supportedFilesystems = [ "nfs" ];
  fileSystems."/srv/immich-media" = {
    fsType = "nfs";
    device = "storage.ritter.family:/mnt/default-pool/immich-media";
  };
  systemd.services.immich = {
    unitConfig = {
      RequiresMountsFor = "/srv/immich-media";
    };
  };
  services.immich.mediaLocation = "/srv/immich-media";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
