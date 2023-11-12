{pkgs, ...}: {
  imports = [
    ./modules/gh
    ./modules/git
    ./modules/git/pi-hole-identity.nix
    ./modules/gpg
    ./modules/helix
    ./modules/terminal
  ];
}
