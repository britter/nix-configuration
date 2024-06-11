{inputs, ...}: {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  my = {
    host = {
      name = "raspberry-pi";
      system = "aarch64-linux";
      role = "server";
    };
    user = {
      # default name baked into the ARM ISO image
      name = "nixos";
      signingKey = "92166C2B83447076";
    };
    modules.adguard.enable = true;
  };

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
