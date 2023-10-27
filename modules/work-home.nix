{ pkgs, ... }:

{
  imports = [
    # ./firefox
    ./gh
    # ./git
    ./gpg
    ./helix
    # ./java
    ./terminal
  ];
}
