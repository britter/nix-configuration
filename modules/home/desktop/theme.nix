{ inputs, ... }:
{
  # catppuccin aspect with a module for each context it applies to
  flake.modules.nixos.theme = {
    imports = [ inputs.catppuccin.nixosModules.catppuccin ];

    catppuccin = {
      enable = true;
      flavor = "macchiato";
      accent = "teal";
    };
  };

  flake.modules.homeManager.theme = { pkgs, ... }: {
    imports = [ inputs.catppuccin.homeModules.catppuccin ];

    catppuccin = {
      autoEnable = true;
      enable = true;
      flavor = "macchiato";
      accent = "teal";
    };

    home.pointerCursor = {
      enable = true;
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 32;
      gtk.enable = true;
    };
  };
}
