{
  description = "Minimal development shell";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs = inputs: {
    devShells = builtins.mapAttrs (_system: pkgs: {
      default = pkgs.mkShell {
        packages = [
          pkgs.hello
        ];
      };
    }) inputs.nixpkgs.legacyPackages;
  };
}
