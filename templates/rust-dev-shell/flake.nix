{
  description = "Rust development shell";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      # Replaces flake-utils' eachDefaultSystem with plain stdlib.
      forAll = f: builtins.mapAttrs (system: pkgs: f system pkgs) inputs.nixpkgs.legacyPackages;
    in
    {
      checks = forAll (
        system: pkgs: {
          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt.enable = true;
              rustfmt.enable = true;
              clippy.enable = true;
            };
            # clippy needs the dependencies of the crate to be available.
            settings.rust.check.cargoDeps = pkgs.rustPlatform.importCargoLock {
              lockFile = ./Cargo.lock;
            };
          };
        }
      );

      devShells = forAll (
        system: pkgs:
        let
          inherit (inputs.self.checks.${system}.pre-commit-check) shellHook enabledPackages;
        in
        {
          default = pkgs.mkShell {
            inherit shellHook;
            packages = [
              pkgs.cargo
              pkgs.clippy
              pkgs.rust-analyzer
              pkgs.rustc
            ]
            ++ enabledPackages;
          };
        }
      );
    };
}
