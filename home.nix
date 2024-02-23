{pkgs, ...}: {
  imports = [
    ./home/desktop
    ./home/gh
    ./home/git
    ./home/git/private-identity.nix
    ./home/gpg
    ./home/gradle
    ./home/helix
    ./home/java
    ./home/terminal
  ];

  programs.gradle = {
    enable = true;
    settings = {
      "org.gradle.java.installations.paths" = "${pkgs.jdk8},${pkgs.jdk11}";
    };
  };
}
