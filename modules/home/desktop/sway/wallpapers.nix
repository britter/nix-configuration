{
  flake.modules.homeManager.noctalia =
    { pkgs, ... }:
    {
      home.file.".cache/noctalia/wallpapers.json".text = builtins.toJSON {
        defaultWallpaper = "${pkgs.wallpapers}/landscapes/Clearday.jpg";
      };
      # Doesn't seem to work, see https://github.com/noctalia-dev/noctalia/issues/4044
      programs.noctalia.settings.wallpaper.default.path = "${pkgs.wallpapers}/landscapes/Clearday.jpg";
      programs.noctalia.settings.wallpaper.directory = "${pkgs.wallpapers}";
    };
}
