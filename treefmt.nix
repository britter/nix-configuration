_: {
  projectRootFile = "flake.nix";
  programs = {
    deadnix.enable = true;
    keep-sorted.enable = true;
    nixfmt-rfc-style.enable = true;
    statix.enable = true;
    stylua.enable = true;
  };
  settings.formatter.stylua.options = [
    "--indent-type"
    "Spaces"
  ];
}
