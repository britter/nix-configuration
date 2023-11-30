{pkgs, ...}: {
  imports = [
    # ./home/firefox
    ./home/gh
    ./home/git
    ./home/git/work-identity.nix
    ./home/gpg
    ./home/gradle
    ./home/helix
    ./home/java
    ./home/terminal
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
