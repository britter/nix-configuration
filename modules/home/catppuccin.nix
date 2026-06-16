{ inputs, ... }:
{
  flake.modules.homeManager.catppuccin = {
    imports = [
      inputs.catppuccin.homeModules.catppuccin
    ];

    catppuccin = {
      autoEnable = true;
      enable = true;
      flavor = "macchiato";
    };

  };
}
