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

  flake.modules.nixos.${username} =
    { pkgs, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      users.users.${username} = {
        isNormalUser = true;
        description = fullName;
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        shell = pkgs.fish;
      };
      programs.fish.enable = true;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username}.imports = [ config.flake.modules.homeManager.${username} ];
      };
    };

  flake.modules.homeManager.${username} =
    { lib, ... }:
    {
      imports = [
        config.flake.modules.generic.home-lab
        config.flake.modules.homeManager.user-identity
        inputs.catppuccin.homeModules.catppuccin
        inputs.nixvim.homeModules.nixvim

        ../../_needs_migration/home
      ];

      home.username = lib.mkDefault username;
      home.homeDirectory = lib.mkDefault "/home/${username}";
      home.stateVersion = "23.05";

      user = {
        inherit fullName email signingKey;
      };
    };

  flake.homeConfigurations = config.flake.lib.mkHomeManager "x86_64-linux" username;
}
