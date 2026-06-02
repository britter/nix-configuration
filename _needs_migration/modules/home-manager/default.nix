{
  config,
  lib,
  inputs,
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
      extraSpecialArgs = { inherit inputs; };
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${myUser.name} = {
        imports = [ inputs.self.modules.homeManager.${myUser.name} ];
      };
    };
  };
}
