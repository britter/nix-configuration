{
  pkgs-unstable,
  my-pkgs,
}: _final: _prev:
{
  inherit (pkgs-unstable) jetbrains;
}
// my-pkgs
