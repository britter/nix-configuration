{lib, ...}: {
  programs._1password-gui.enable = true;

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "1password"
    ];
}
