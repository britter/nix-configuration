{ inputs, ... }:
{
  flake.modules.nixos.system-desktop = {
    imports = [ inputs.self.modules.nixos.system-base ];
    networking.networkmanager.enable = true;
  };
}
