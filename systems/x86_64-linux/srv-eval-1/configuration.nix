{ ... }:
{
  imports = [
    ../../../modules
  ];

  my = {
    host = {
      role = "server";
    };
    modules = {
      proxmox-vm.enable = true;
      disko = {
        enable = true;
        bootDisk = "/dev/sda";
      };
      tailscale.enable = true;
    };
  };

  services.calibre-web = {
    enable = true;
    listen.ip = "0.0.0.0";
    openFirewall = true;
    options = {
      enableBookConversion = true;
      enableBookUploading = true;
      enableKepubify = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
