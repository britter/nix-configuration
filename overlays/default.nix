{
  pkgs-unstable,
  my-pkgs,
  nur,
}: _final: _prev:
{
  inherit (pkgs-unstable) jetbrains;
}
// my-pkgs
// (nur.overlays.default _final _prev)
