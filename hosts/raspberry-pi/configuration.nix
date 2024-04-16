{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../../modules
    ../../modules/adguard
  ];

  my = {
    role = "server";
    modules.i18n.enable = true;
  };

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  nixpkgs = let
    system = "aarch64-linux";
  in {
    hostPlatform = lib.mkDefault system;
    overlays = inputs.self.overlays.${system};
  };

  networking.hostName = "raspberry-pi";

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.fish;
    openssh.authorizedKeys.keyFiles = [./bene_rsa.pub];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nixos = {
      home.stateVersion = "23.05";
      imports = [
        inputs.catppuccin.homeManagerModules.catppuccin
        ../../home/raspberry-pi.nix
      ];
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
