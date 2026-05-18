{ inputs, ... }:
{
  flake.modules.homeManager.benedikt = {
    imports = [
      inputs.catppuccin.homeModules.catppuccin
      inputs.nixvim.homeModules.nixvim

      ../../home/benedikt.nix
    ];

    nixpkgs.overlays = [
      inputs.self.overlays.default
    ];
    nixpkgs.config.allowUnfreePackages = [
      "terraform"
      "claude-code"
    ];
  };
}
