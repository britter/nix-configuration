{ config, ... }:
{
  flake.modules.nixos.framework-13 = {
    imports = with config.flake.modules.nixos; [
      system-desktop
      bene-on-framework-13
      gaming
      printing
      podman
      tailscale
      fhs-support
    ];

    system.stateVersion = "25.05";
  };
}
