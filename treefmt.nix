_: {
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    keep-sorted.enable = true;
    statix.enable = true;
    stylua.enable = true;
  };
  settings.formatter.stylua.options = ["--indent-type" "Spaces"];
}
