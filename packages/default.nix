{ pkgs, ... }:
{
  clipmd = pkgs.callPackage ./clipmd { };
  gh-get = pkgs.callPackage ./gh-get { };
  groovy-language-server = pkgs.callPackage ./groovy-language-server { };
  jfmt-java = pkgs.callPackage ./jfmt-java { };
  kotlin-lsp = pkgs.callPackage ./kotlin-lsp { };
  nixpkgs-pr = pkgs.callPackage ./nixpkgs-pr { };
  wallpapers = pkgs.callPackage ./wallpapers { };
}
