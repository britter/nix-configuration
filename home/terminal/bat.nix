{
  pkgs,
  lib,
  ...
}: let
  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat";
    rev = "b19bea35a85a32294ac4732cad5b0dc6495bed32";
    sha256 = "sha256-POoW2sEM6jiymbb+W/9DKIjDM1Buu1HAmrNP0yC2JPg=";
  };
  styles = ["Frappe" "Latte" "Macchiato" "Mocha"];
in {
  programs.bat = {
    enable = true;
    themes = builtins.listToAttrs (
      map
      (style: {
        name =  "Catppuccin ${style}";
        value = {
          src = catppuccin;
          file = "themes/Catppuccin ${style}.tmTheme";
        };
      })
      styles
    );
    config.theme = "Catppuccin Macchiato";
  };
}
