{ pkgs, ... }:
{
  gh-get = pkgs.callPackage ./gh-get { };
  groovy-language-server = pkgs.callPackage ./groovy-language-server { };
  jfmt-java = pkgs.callPackage ./jfmt-java { };
  kotlin-lsp = pkgs.callPackage ./kotlin-lsp { };
  wallpapers = pkgs.callPackage ./wallpapers { };
}
