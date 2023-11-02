{pkgs, ...}: {
  imports = [
    ./modules/firefox
    ./modules/gh
    ./modules/git
    ./modules/git/private-identity.nix
    ./modules/gpg
    ./modules/gradle
    ./modules/helix
    ./modules/java
    ./modules/terminal
  ];

  programs.gradle = {
    enable = true;
    additionalJavaPackages = [pkgs.jdk8];
  };
}
