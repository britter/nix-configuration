{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gradle
  ];

  home.sessionVariables = {
    JDK8 = "${pkgs.jdk8}";
  };

  programs.java = {
    enable = true;
    package = pkgs.jdk17;
  };
}
