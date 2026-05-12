{ config, ... }:
{
  flake.nixosConfigurations.minimal-server-iso = config.flake.lib.mkNixos "x86_64-linux" "minimal-server-iso";
}
