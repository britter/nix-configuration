{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.user;
in {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${cfg.name} = {
      home.stateVersion = "23.05";
      imports = [
        inputs.catppuccin.homeManagerModules.catppuccin
        ../../../home
      ];
    };
  };
}
