_: {
  flake.allowUnfreePackages = [ "obsidian" ];

  flake.modules.homeManager.obsidian =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.obsidian ];
    };
}
