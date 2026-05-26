{ inputs, ... }:
{
  # Declarative disk partitioning and formatting
  # https://github.com/nix-community/disko
  imports = [ inputs.disko.flakeModules.disko ];
}
