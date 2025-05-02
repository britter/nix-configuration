{ ... }:

{
  imports = [
    #    ./java
    #    ./terminal
  ];

  home.username = "benedikt";
  home.homeDirectory = "/home/benedikt";
  home.stateVersion = "24.11"; # Please read the comment before changing.

  programs.home-manager.enable = true;
}
