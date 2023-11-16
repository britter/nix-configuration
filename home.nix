{pkgs, ...}: {
  imports = [
    ./home/firefox
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
