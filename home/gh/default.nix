{pkgs, ...}: let
  mypkgs = import ../../packages {inherit pkgs;};
in {
  programs.gh = {
    enable = true;

    extensions = [mypkgs.gh-get];
  };
}
