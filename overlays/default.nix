{
  my-pkgs,
  nur,
}:
_final: _prev: my-pkgs // (nur.overlays.default _final _prev)
