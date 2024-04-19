{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.user;
in {
  options.my.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "bene";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Benedikt Ritter";
    };
  };
  config = {
    users.users.${cfg.name} = {
      isNormalUser = true;
      description = cfg.fullName;
      extraGroups = ["networkmanager" "wheel"];
      shell = pkgs.fish;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${cfg.name} = {
        home.stateVersion = "23.05";
        imports = [
          inputs.catppuccin.homeManagerModules.catppuccin
          ../../home
        ];
      };
    };
  };
}
