{
  inputs,
  config,
  ...
}:
let
  username = "bene";
  fullName = "Benedikt Ritter";
  email = "beneritter@gmail.com";
  signingKey = "394546A47BB40E12";
in
{
  flake.allowUnfreePackages = [ "obsidian" ];

  flake.modules.homeManager.${username} =
    { lib, ... }:
    {
      imports = [
        inputs.catppuccin.homeModules.catppuccin
        inputs.nixvim.homeModules.nixvim

        ../../_needs_migration/home
      ];

      home.username = lib.mkDefault username;
      home.homeDirectory = lib.mkDefault "/home/${username}";
      home.stateVersion = "23.05";
    };

  flake.homeConfigurations.${username} = config.flake.lib.mkHomeManager "x86_64-linux" username {
    osConfig.my.user = {
      inherit fullName email signingKey;
    };
  };
}
