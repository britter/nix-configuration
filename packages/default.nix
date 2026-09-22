{ pkgs, ... }:
{
  clipmd = pkgs.callPackage ./clipmd { };
  gh-get = pkgs.callPackage ./gh-get { };
  jfmt-java = pkgs.callPackage ./jfmt-java { };
  kotlin-lsp = pkgs.callPackage ./kotlin-lsp { };
  nixpkgs-pr = pkgs.callPackage ./nixpkgs-pr { };
  wallpapers = pkgs.callPackage ./wallpapers { };
}
