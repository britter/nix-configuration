{pkgs, ...}: {
  imports = [
    ./desktop
    ./gh
    ./git
    ./git/private-identity.nix
    ./gpg
    ./gradle
    ./helix
    ./java
    ./terminal
  ];

  programs.gradle = {
    enable = true;
    settings = {
      "org.gradle.java.installations.paths" = "${pkgs.jdk8},${pkgs.jdk11}";
    };
  };
}
