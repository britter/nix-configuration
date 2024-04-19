{pkgs, ...}: {
  imports = [
    ./gh
    ./git
    ./git/private-identity.nix
    ./gpg
    ./gradle
    ./helix
    ./java
  ];

  programs.gradle = {
    enable = true;
    settings = {
      "org.gradle.java.installations.paths" = "${pkgs.jdk8},${pkgs.jdk11}";
    };
  };
}
