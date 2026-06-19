_: {
  flake.modules.nixos.bitwarden = {
    # bitwarden-desktop ships with an outdated electron
    nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];
  };

  flake.modules.homeManager.bitwarden =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.bitwarden-desktop ];
    };
}
