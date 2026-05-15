{ config, ... }:
{
  flake.nixosConfigurations.framework-13 = config.flake.lib.mkNixos "x86_64-linux" "framework-13";
}
