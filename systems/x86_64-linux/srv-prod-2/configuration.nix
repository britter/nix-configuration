{...}: {
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
        storageDisk = "/dev/sdb";
      };
      git-server.enable = true;
      nextcloud = {
        enable = true;
        stage = "production";
      };
      vaultwarden.enable = true;
    };
  };

  users.users = {
    nextcloud = {
      openssh.authorizedKeys.keyFiles = [../srv-test-2/ssh_srv-test-2_ed25519_key.pub];
      useDefaultShell = true;
    };
    git = {
      openssh.authorizedKeys.keyFiles = [../srv-test-2/ssh_srv-test-2_ed25519_key.pub];
      useDefaultShell = true;
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
