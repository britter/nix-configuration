{ inputs, ... }:
{
  flake.modules.homeManager.catppuccin = {
    imports = [
      inputs.catppuccin.homeModules.catppuccin
    ];

    catppuccin = {
      enable = true;
      flavor = "macchiato";
    };

  };
}
