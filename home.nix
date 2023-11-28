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

  # software not available as Home Manager module
  home.packages = with pkgs; [
    jetbrains.idea-community
    fractal-next
  ];

  programs.gradle = {
    enable = true;
    additionalJavaPackages = [pkgs.jdk8];
  };
}
