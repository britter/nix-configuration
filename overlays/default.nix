{
  my-pkgs,
  nur,
}:
_final: prev:
my-pkgs
// (nur.overlays.default _final prev)
// {
  # https://github.com/NixOS/nixpkgs/pull/477155
  python3 = prev.python3.override {
    packageOverrides = _pyfinal: pyprev: {
      weasyprint = pyprev.weasyprint.overrideAttrs (attrs: {
        disabledTests = attrs.disabledTests ++ [ "test_2d_transform" ];
      });
    };
  };

}
