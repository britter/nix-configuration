{
  inputs,
  ...
}:
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

    nixpkgs.overlays = [ inputs.self.overlays.default ];
  };
}
