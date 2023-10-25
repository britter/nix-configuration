{ pkgs, ... }:

{
  imports = [
    ./gh
    ./git
    ./gpg
    ./helix
    ./java
    ./terminal
  ];

  programs.firefox.enable = true;
}
