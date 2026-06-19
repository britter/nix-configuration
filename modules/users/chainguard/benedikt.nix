{
  inputs,
  config,
  ...
}:
let
  username = "benedikt";
  fullName = "Benedikt Ritter";
  email = "beneritter@gmail.com";
  signingKey = "14907572088F4FA7";
in
{
  flake.allowUnfreePackages = [
    "terraform"
    "claude-code"
  ];

  flake.modules.homeManager.${username} =
    { lib, ... }:
    {
      imports = with config.flake.modules.homeManager; [
        user-base
        git-chainguard
        intellij

        inputs.nixvim.homeModules.nixvim
        ../../../_needs_migration/home/benedikt.nix
      ];

      home.username = lib.mkDefault username;
      home.homeDirectory = lib.mkDefault "/home/${username}";
      home.stateVersion = "24.11";

      user = {
        inherit fullName email signingKey;
      };
    };

  flake.homeConfigurations = config.flake.lib.mkHomeManager "x86_64-linux" username;
}
