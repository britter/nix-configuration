_: {
  flake.allowUnfreePackages = [ "slack" ];

  flake.modules.homeManager.slack =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.slack ];
    };
}
