{pkgs, ...}: {
  imports = [
    ../../../modules
    ./nextcloud-sync.nix
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
        storageDisk = "/dev/sdb";
      };
      nextcloud = {
        enable = true;
        stage = "test";
      };
      vaultwarden.enable = true;
    };
  };

  users.users.git = {
    isSystemUser = true;
    group = "git";
    description = "git user";
    home = "/srv/git";
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keyFiles = [../../../modules/ssh-access/id_ed25519.pub];
  };
  users.groups.git = {};

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
