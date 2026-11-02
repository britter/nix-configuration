{ pkgs, ... }:
{
  clipmd = pkgs.callPackage ./clipmd { };
  fix-gradle-console = pkgs.callPackage ./fix-gradle-console { };
  gh-get = pkgs.callPackage ./gh-get { };
  kotlin-lsp = pkgs.callPackage ./kotlin-lsp { };
  skills-ref = pkgs.callPackage ./skills-ref { };
  ste-lint = pkgs.callPackage ./ste-lint { };
  testlens-cli = pkgs.callPackage ./testlens-cli { };
  wallpapers = pkgs.callPackage ./wallpapers { };
}
