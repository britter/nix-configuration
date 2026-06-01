{ config, ... }:
{
  flake.modules.nixos.system-desktop = {
    imports = [ config.flake.modules.nixos.system-base ];
    networking.networkmanager.enable = true;
  };
}
