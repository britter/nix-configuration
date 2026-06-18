{ inputs, ... }:
{
  flake.modules.nixos.framework-13 = {
    imports = [ inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series ];

    hardware.facter.reportPath = ./facter.json;
    # see https://github.com/numtide/nixos-facter-modules/issues/62
    hardware.facter.detected.dhcp.enable = false;
  };
}
