{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.modules.home-manager;
  myUser = config.my.user;
in {
  options.my.modules.home-manager = {
    enable = lib.mkEnableOption "home-manager";
  };
  config = lib.mkIf cfg.enable {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${myUser.name} = {
        home.stateVersion = "23.05";
        imports = [
          inputs.catppuccin.homeManagerModules.catppuccin
          ../../../home
        ];
      };
    };
  };
}
