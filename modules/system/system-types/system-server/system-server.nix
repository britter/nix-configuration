{ config, ... }:
{
  flake.modules.nixos.system-server = {
    imports = [ config.flake.modules.nixos.system-base ];
  };
}
