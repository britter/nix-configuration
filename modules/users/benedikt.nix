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
      imports = with config.flake.modules.homeManager; [
        config.flake.modules.generic.home-lab
        user-identity
        catppuccin
        fish
        gpg
        terminal-essentials
        tmux
        tools

        inputs.nixvim.homeModules.nixvim
        ../../_needs_migration/home/benedikt.nix
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
