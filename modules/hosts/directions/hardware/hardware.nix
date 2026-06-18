{ inputs, ... }:
{
  flake.modules.nixos.directions =
    {
      pkgs,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
      ];

      boot.loader = {
        grub.enable = false;
        generic-extlinux-compatible.enable = true;
      };

      boot.initrd.availableKernelModules = [ "xhci_pci" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ ];
      boot.extraModulePackages = [ ];

      # workaround for https://github.com/NixOS/nixos-hardware/commit/c8f766fd11c8b0a9832b6ca1819de74fbfee3d73
      # the Raspberry Pi kernel is about to be removed from nixpkgs, so the aforementioned commit adds
      # a custom derivation that builds it from scratch. Since nixos-hardware does not have a binary
      # cache is causes a kernel rebuild on this machine, which takes very long.
      # See also https://github.com/NixOS/nixos-hardware/issues/325#issuecomment-4199711155
      # overrides the vendored Raspberry Pi kernel, that is configured by nixos-hardware with
      # the mainline kernel
      boot.kernelPackages = pkgs.linuxPackages;

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
        fsType = "ext4";
      };

      swapDevices = [ ];

      networking.useDHCP = lib.mkDefault true;

      powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
    };
}
