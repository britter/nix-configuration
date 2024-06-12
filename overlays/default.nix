{
  pkgs-unstable,
  my-pkgs,
  nur,
  nixpkgs-terraform,
}: _final: _prev:
{
  inherit (pkgs-unstable) jetbrains;
}
// my-pkgs
// (nur.overlay _final _prev)
// (nixpkgs-terraform.overlays.default _final _prev)
