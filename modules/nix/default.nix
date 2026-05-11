{
  config,
  inputs,
  ...
}:
let
  inherit (config.my.host) system;
in
{
  config = {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
      };
    };

    nixpkgs.overlays = [ inputs.self.overlays.${system} ];
  };
}
