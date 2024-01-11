{pkgs, ...}:
with pkgs; rec {
  baresip-studio-link = callPackage ./baresip-studio-link {libre = studio-link-libre;};
  gh-get = callPackage ./gh-get {};
  groovy-language-server = callPackage ./groovy-language-server {};
  overlay-vst = callPackage ./overlay-vst {inherit baresip-studio-link vst-sdk;};
  studio-link-libre = callPackage ./studio-link-libre {};
  vst-sdk = callPackage ./vst-sdk {};
}
