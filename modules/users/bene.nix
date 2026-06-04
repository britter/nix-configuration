{
  inputs,
  config,
  ...
}:
let
  username = "bene";
  fullName = "Benedikt Ritter";
  email = "beneritter@gmail.com";
  # signingKey defaults to bene's standalone-HM (starlabs) key. The
  # framework-13 host overrides this via bene-on-framework-13.nix because
  # signing keys are per-machine.
  signingKey = "1232C0894CC635B5";
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

        ../../_needs_migration/home/terminal
      ];

      home.username = lib.mkDefault username;
      home.homeDirectory = lib.mkDefault "/home/${username}";
      home.stateVersion = "23.05";

      catppuccin = {
        enable = true;
        flavor = "macchiato";
      };

      my.home.terminal.enable = true;

      user = {
        inherit fullName email;
        signingKey = lib.mkDefault signingKey;
      };
    };

  flake.homeConfigurations = config.flake.lib.mkHomeManager "x86_64-linux" username;
}
