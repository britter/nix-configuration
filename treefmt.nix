_: {
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    keep-sorted.enable = true;
    statix.enable = true;
  };
}
