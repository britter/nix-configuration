{
  config,
  lib,
  inputs,
  home-lab,
  ...
}:
let
  cfg = config.my.modules.home-manager;
  myUser = config.my.user;
in
{
  options.my.modules.home-manager = {
    enable = lib.mkEnableOption "home-manager";
  };
  config = lib.mkIf cfg.enable {
    home-manager = {
      extraSpecialArgs = { inherit inputs home-lab; };
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${myUser.name} = {
        home.stateVersion = "23.05";
        imports = [
          inputs.catppuccin.homeModules.catppuccin
          inputs.nixvim.homeManagerModules.nixvim
          ../../home
        ];
      };
    };
    my.modules.allowedUnfreePkgs = [
      "obsidian"
      # required by terraformls used in nixvim configuration
      "terraform"
    ];
  };
}
