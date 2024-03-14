{pkgs, ...}: {
  imports = [
    ./gh
    ./git
    ./git/work-identity.nix
    ./gpg
    ./gradle
    ./helix
    ./java
    ./terminal
  ];

  home.sessionVariables = with pkgs; {
    JDK8 = jdk8;
    JDK11 = jdk11;
    JDK17 = jdk17;
    JDK20 = jdk20;
    JDK21 = jdk21;
  };

  programs.gradle.enable = true;
}
