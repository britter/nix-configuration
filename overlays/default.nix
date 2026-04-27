{
  my-pkgs,
  nur,
}:
final: prev:
my-pkgs
// (nur.overlays.default final prev)
// {
  calibre-web = prev.calibre-web.overrideAttrs (prev: {
    pythonRelaxDeps = prev.pythonRelaxDeps ++ [ "requests" ];
  });
}
