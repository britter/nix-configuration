{
  my-pkgs,
  nur,
}:
final: prev: my-pkgs // (nur.overlays.default final prev)
