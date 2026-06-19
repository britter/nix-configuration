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

      cursors = {
        enable = true;
        accent = "dark";
      };

      # librewolf's catppuccin theme is applied via the librewolf aspect's
      # explicit profile config rather than through this auto-styling.
      librewolf.profiles.bene.enable = false;
    };
  };
}
