{pkgs, ...}: {
  imports = [
    ./git
    ./git/private-identity.nix
    ./gpg
  ];

  programs.gradle = {
    settings = {
      "org.gradle.java.installations.paths" = "${pkgs.jdk8},${pkgs.jdk11}";
    };
  };
}
