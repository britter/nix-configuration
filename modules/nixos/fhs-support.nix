_: {
  # nix-ld provides an FHS-style loader so unpatched dynamic binaries can run.
  flake.modules.nixos.fhs-support = {
    programs.nix-ld.enable = true;
  };
}
