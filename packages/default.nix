{pkgs, ...}:
with pkgs; rec {
  gh-get = callPackage ./gh-get {};
  groovy-language-server = callPackage ./groovy-language-server {};
  opus = callPackage ./opus {};
  overlay-onair-lv2 = callPackage ./overlay-onair-lv2 {
    inherit opus;
    baresip = studio-link-baresip;
    libre = studio-link-libre;
  };
  overlay-vst = callPackage ./overlay-vst {
    inherit vst-sdk opus;
    baresip = studio-link-baresip;
    libre = studio-link-libre;
  };
  studio-link-baresip = callPackage ./studio-link-baresip {
    inherit opus;
    libre = studio-link-libre;
    librem = studio-link-librem;
  };
  studio-link-libre = callPackage ./studio-link-libre {};
  studio-link-librem = callPackage ./studio-link-librem {libre = studio-link-libre;};
  vst-sdk = callPackage ./vst-sdk {};
}
