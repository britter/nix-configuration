{ config, ... }:
{
  flake.modules.nixos.framework-13 = {
    imports = with config.flake.modules.nixos; [
      system-desktop
      bene-on-framework-13
      gaming
      nix-community-builders
      printing
      scanning
      podman
      tailscale
      yubikey
      testlens-support
      seeq-support
    ];

    system.stateVersion = "25.05";
  };
}
