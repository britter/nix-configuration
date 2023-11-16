{pkgs, ...}: {
  imports = [
    ./home/gh
    ./home/git
    ./home/git/pi-hole-identity.nix
    ./home/gpg
    ./home/helix
    ./home/terminal
  ];
}
