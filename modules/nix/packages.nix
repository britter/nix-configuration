_: {
  perSystem =
    { pkgs, ... }:
    {
      packages = import ../../packages { inherit pkgs; };
    };
}
