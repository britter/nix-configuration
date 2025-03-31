{
  lib,
  pkgs,
  ...
}:
let
  catppuccin-wallpapers = pkgs.fetchFromGitHub {
    owner = "zhichaoh";
    repo = "catppuccin-wallpapers";
    rev = "1023077979591cdeca76aae94e0359da1707a60e";
    sha256 = "sha256-h+cFlTXvUVJPRMpk32jYVDDhHu1daWSezFcvhJqDpmU=";
  };
in
{
  options.my.home.desktop.wallpapers = {
    evening-sky = lib.mkOption {
      type = lib.types.path;
      default = "${catppuccin-wallpapers}/landscapes/evening-sky.png";
    };
  };
}
