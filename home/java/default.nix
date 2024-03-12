{pkgs, ...}: {
  imports = [
    ./helix-java-support.nix
  ];
  programs.java = {
    enable = true;
    package = pkgs.jdk21;
  };
}
