{pkgs, ...}: {
  imports = [../gradle];

  programs.java = {
    enable = true;
    package = pkgs.jdk17;
  };

  programs.gradle = {
    enable = true;
    additionalJavaPackages = [pkgs.jdk8];
  };
}
