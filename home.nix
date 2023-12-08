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
    additionalJavaPackages = [pkgs.jdk8];
  };
}
