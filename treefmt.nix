{
  lib,
  pkgs,
  ...
}: {
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true;
  };
}
