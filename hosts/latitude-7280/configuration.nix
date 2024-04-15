{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.dell-latitude-7280
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../../modules
    ../../modules/gnome
    ../../modules/nix
  ];

  my.modules = {
    _1password.enable = true;
    disko = {
      enable = true;
      disk = "/dev/sda";
      swapSize = "8GB";
    };
    i18n.enable = true;
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
    hostName = "latitude-7280";
    networkmanager.enable = true;
  };

  services.printing.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.bene = {
    isNormalUser = true;
    description = "Benedikt";
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
  system.stateVersion = "22.11"; # Did you read the comment?
}
