{ pkgs, ... }:

let
  gh-get = import ./gh-get.nix { inherit pkgs; };
in
{
  programs.gh = {
    enable = true;

    extensions = [ gh-get.gh-get ];
  };
}
