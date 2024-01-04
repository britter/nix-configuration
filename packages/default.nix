{pkgs, ...}:
with pkgs; rec {
  baresip-studio-link = callPackage ./baresip-studio-link {};
  gh-get = callPackage ./gh-get {};
  groovy-language-server = callPackage ./groovy-language-server {};
  overlay-vst = callPackage ./overlay-vst {inherit baresip-studio-link vst-sdk;};
  vst-sdk = callPackage ./vst-sdk {};
}
