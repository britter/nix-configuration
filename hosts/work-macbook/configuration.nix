{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ../../modules/common-utilities
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nixpkgs = let
    system = "aarch64-darwin";
  in {
    hostPlatform = lib.mkDefault system;
    overlays = inputs.self.overlays.${system};
  };

  # Host name has to equal serial number of the machine due to company device management
  networking.hostName = "WQ0C6FWJ1W";

  users.users.bene = {
    name = "bene";
    home = "/Users/bene";
    shell = pkgs.fish;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.bene = {
      home.stateVersion = "23.05";
      imports = [
        inputs.catppuccin.homeManagerModules.catppuccin
        ../../home/work-macbook.nix
      ];
    };
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
