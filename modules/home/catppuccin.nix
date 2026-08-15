{ inputs, ... }:
{
  flake.modules.homeManager.catppuccin =
    { pkgs, ... }:
    {
      imports = [
        inputs.catppuccin.homeModules.catppuccin
      ];

      catppuccin = {
        autoEnable = true;
        enable = true;
        flavor = "macchiato";
        accent = "sky";
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
