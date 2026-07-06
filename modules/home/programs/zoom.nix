_: {
  flake.allowUnfreePackages = [ "zoom" ];

  flake.modules.homeManager.zoom =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zoom-us ];
    };
}
