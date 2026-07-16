{
  flake.modules.homeManager.noctalia =
    { pkgs, ... }:
    {
      home.file.".cache/noctalia/wallpapers.json".text = builtins.toJSON {
        defaultWallpaper = "${pkgs.wallpapers}/landscapes/Clearday.jpg";
      };
    };
}
