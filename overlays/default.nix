{
  my-pkgs,
  nur,
}:
final: prev:
my-pkgs
// (nur.overlays.default final prev)
// {
  # See https://github.com/NixOS/nixpkgs/pull/494140
  calibre-web = prev.calibre-web.overrideAttrs {
    version = "0.6.27-unstable-2026-02-22";
    src = final.fetchFromGitHub {
      owner = "janeczku";
      repo = "calibre-web";
      rev = "5e48a64b1517574c31cf667be8c45bcd05cd0904";
      hash = "sha256-OgaU+Kj24AzalMM8dhelJz1L8akadJoJApQw3q8wbCc=";
    };
  };
  # See https://github.com/NixOS/nixpkgs/issues/493843
  # Fix adopted from https://github.com/NixOS/nixpkgs/commit/3428d5442b9b5c3772c496cbbaf8ba52d86ef667
  calibre = prev.calibre.overrideAttrs {
    installPhase = ''
      runHook preInstall

      export QMAKE="${prev.qt6.qtbase}/bin/qmake"

      python setup.py install --root=$out \
      --prefix=$out \
      --libdir=$out/lib \
      --staging-root=$out \
      --staging-libdir=$out/lib \
      --staging-sharedir=$out/share

      PYFILES="$out/bin/* $out/lib/calibre/calibre/web/feeds/*.py
      $out/lib/calibre/calibre/ebooks/metadata/*.py
      $out/lib/calibre/calibre/ebooks/rtf2xml/*.py"

      sed -i "s/env python[0-9.]*/python/" $PYFILES
      sed -i "2i import sys; sys.argv[0] = 'calibre'" $out/bin/calibre

      mkdir -p $out/share
      cp -a man-pages $out/share/man

      runHook postInstall
    '';
  };
}
