{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../../modules
  ];

  my = {
    role = "desktop";
    modules = {
      disko = {
        enable = true;
        disk = "/dev/nvme0n1";
        swapSize = "32GB";
      };
    };
  };

  nixpkgs = let
    system = "x86_64-linux";
  in {
    hostPlatform = lib.mkDefault system;
    overlays = inputs.self.overlays.${system};
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "pulse-14";
    networkmanager.enable = true;
  };

  services.printing.enable = true;

  users.users.bene = {
    isNormalUser = true;
    description = "Benedikt Ritter";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.fish;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.bene = {
      home.stateVersion = "23.05";
      imports = [
        inputs.catppuccin.homeManagerModules.catppuccin
        ../../home/latitude.nix
      ];
    };
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["FiraCode"];})
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
