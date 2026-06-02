{ inputs, config, ... }:
{
  flake.modules.nixos.directions =
    { pkgs, ... }:
    {
      imports = [
        ../../../_needs_migration/modules
        config.flake.modules.nixos.directions-hardware
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
        config.flake.modules.nixos.system-server
        (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
      ];

      # workaround for https://github.com/NixOS/nixos-hardware/commit/c8f766fd11c8b0a9832b6ca1819de74fbfee3d73
      # the Raspberry Pi kernel is about to be removed from nixpkgs, so the aforementioned commit adds
      # a custom derivation that builds it from scratch. Since nixos-hardware does not have a binary
      # cache is causes a kernel rebuild on this machine, which takes very long.
      # See also https://github.com/NixOS/nixos-hardware/issues/325#issuecomment-4199711155
      # overrides the vendored Raspberry Pi kernel, that is configured by nixos-hardware with
      # the mainline kernel
      boot.kernelPackages = pkgs.linuxPackages;

      my.modules = {
        adguard.enable = true;
        homepage.enable = true;
        tailscale.enable = true;
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
    };
}
