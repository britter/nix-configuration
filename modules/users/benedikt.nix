{
  inputs,
  config,
  ...
}:
let
  username = "benedikt";
  fullName = "Benedikt Ritter";
  email = "benedikt.ritter@chainguard.dev";
  signingKey = "EA363E64382563CF";
in
{
  flake.allowUnfreePackages = [
    "terraform"
    "claude-code"
  ];

  flake.modules.homeManager.${username} =
    { lib, ... }:
    {
      imports = [
        config.flake.modules.generic.home-lab
        inputs.catppuccin.homeModules.catppuccin
        inputs.nixvim.homeModules.nixvim

        ../../_needs_migration/home/benedikt.nix
      ];

      home.username = lib.mkDefault username;
      home.homeDirectory = lib.mkDefault "/home/${username}";
      home.stateVersion = "24.11";
    };

  flake.homeConfigurations.${username} = config.flake.lib.mkHomeManager "x86_64-linux" username {
    osConfig.my.user = {
      inherit fullName email signingKey;
    };
  };
}
