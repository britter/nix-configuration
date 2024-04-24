{pkgs, ...}: {
  imports = [
    ./git/private-identity.nix
  ];

  programs.gradle = {
    settings = {
      "org.gradle.java.installations.paths" = "${pkgs.jdk8},${pkgs.jdk11}";
    };
  };
}
