{ config, ... }:
{
  flake.modules.nixos.system-server = {
    imports = with config.flake.modules.nixos; [
      system-base
      ssh-access
      https-proxy
    ];
  };
}
