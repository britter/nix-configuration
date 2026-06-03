{
  flake.modules.homeManager.noctalia =
    { pkgs, ... }:
    let
      catppuccin-wallpapers = pkgs.fetchFromGitHub {
        owner = "zhichaoh";
        repo = "catppuccin-wallpapers";
        rev = "1023077979591cdeca76aae94e0359da1707a60e";
        sha256 = "sha256-h+cFlTXvUVJPRMpk32jYVDDhHu1daWSezFcvhJqDpmU=";
      };
    in
    {
      home.file.".cache/noctalia/wallpapers.json".text = builtins.toJSON {
        defaultWallpaper = "${catppuccin-wallpapers}/landscapes/Clearday.jpg";
      };
    };
}
