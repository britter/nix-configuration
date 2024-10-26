{
  pkgs-unstable,
  my-pkgs,
  nur,
}: _final: _prev:
{
  inherit (pkgs-unstable) jetbrains;
}
// my-pkgs
// (nur.overlay _final _prev)
