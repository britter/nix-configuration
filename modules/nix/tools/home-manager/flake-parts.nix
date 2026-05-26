{ inputs, ... }:
{
  # Manage a user environment using Nix
  # https://github.com/nix-community/home-manager
  imports = [ inputs.home-manager.flakeModules.home-manager ];
}
