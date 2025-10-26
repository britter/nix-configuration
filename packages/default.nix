{ pkgs, ... }:
with pkgs;
{
  lui = callPackage ./lui { };
  gh-get = callPackage ./gh-get { };
  groovy-language-server = callPackage ./groovy-language-server { };
  kotlin-lsp = callPackage ./kotlin-lsp { };
}
