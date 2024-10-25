{
  lib,
  inputs,
  ...
}: {
  imports = [
    ../../../modules/darwin
  ];

  my = {
    host = {
      role = "desktop";
      profiles = ["work"];
    };
    user = {
      email = "benedikt@gradle.com";
      signingKey = "5AEF67FC9BD7F4CA";
    };
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nixpkgs = let
    system = "aarch64-darwin";
  in {
    hostPlatform = lib.mkDefault system;
    overlays = [inputs.self.overlays.${system}];
  };

  # Host name has to equal serial number of the machine due to company device management
  networking.hostName = "WQ0C6FWJ1W";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
