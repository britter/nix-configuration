{pkgs, ...}:
with pkgs; {
  gh-get = callPackage ./gh-get {};
}
