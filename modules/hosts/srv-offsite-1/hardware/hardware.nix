_: {
  flake.modules.nixos.srv-offsite-1 = {
    hardware.facter.reportPath = ./facter.json;
    # see https://github.com/numtide/nixos-facter-modules/issues/62
    hardware.facter.detected.dhcp.enable = false;
  };
}
