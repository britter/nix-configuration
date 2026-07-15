{
  flake.modules.homeManager.noctalia =
    { config, ... }:
    {
      home.file.".cache/noctalia/wallpapers.json".text = builtins.toJSON {
        defaultWallpaper = config.systemConstants.wallpaper;
      };
    };
}
