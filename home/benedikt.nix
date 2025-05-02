{ ... }:

{
  imports = [
    ./java
    ./terminal
  ];

  home.username = "benedikt";
  home.homeDirectory = "/home/benedikt";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  my.home = {
    java = {
      enable = true;
      version = 21;
      additionalVersions = [
        8
        11
        17
      ];
    };
    terminal = {
      enable = true;
      git.enable = false;
      ssh.enable = false;
      gpg.enable = false;
    };
  };
}
