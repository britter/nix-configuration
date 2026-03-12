{ pkgs, ... }:
with pkgs;
rec {
  gh-get = callPackage ./gh-get { };
  groovy-language-server = callPackage ./groovy-language-server { };
  jfmt-java = callPackage ./jfmt-java { inherit maven_4 jfmt-java; };
  kotlin-lsp = callPackage ./kotlin-lsp { };
  maven_4 = callPackage ./maven_4 { };
}
