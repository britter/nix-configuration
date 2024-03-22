{pkgs, ...}: {
  imports = [
    ../../modules/common-utilities
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Host name has to equal serial number of the machine due to company device management
  networking.hostName = "WQ0C6FWJ1W";

  users.users.bene = {
    name = "bene";
    home = "/Users/bene";
    shell = pkgs.fish;
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
