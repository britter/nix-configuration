{pkgs, ...}: {
  imports = [
    ./modules/firefox
    ./modules/gh
    ./modules/git
    ./modules/git/private-identity.nix
    ./modules/gpg
    ./modules/helix
    ./modules/java
    ./modules/terminal
  ];
}
