{pkgs, ...}:
with pkgs; rec {
  gh-get = callPackage ./gh-get {};
  groovy-language-server = callPackage ./groovy-language-server {};
  overlay-vst = callPackage ./overlay-vst {
    inherit vst-sdk;
    baresip = studio-link-baresip;
    libre = studio-link-libre;
  };
  studio-link-baresip = callPackage ./studio-link-baresip {libre = studio-link-libre;};
  studio-link-libre = callPackage ./studio-link-libre {};
  vst-sdk = callPackage ./vst-sdk {};
}
