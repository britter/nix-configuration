{pkgs, ...}:
with pkgs; {
  gh-get = callPackage ./gh-get {};
  groovy-language-server = callPackage ./groovy-language-server {};
  vst-sdk = callPackage ./vst-sdk {};
}
