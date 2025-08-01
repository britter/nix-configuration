{
  description = "A flake for managing my machines";

  inputs = {
    # keep-sorted start block=yes
    catppuccin.url = "github:catppuccin/nix";
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # keep-sorted end
  };

  outputs =
    { self, ... }@inputs:
    let
      lib = import ./lib.nix;
    in
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
        my-pkgs = self.outputs.packages.${system};
        treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      {
        formatter = treefmtEval.config.build.wrapper;
        checks = {
          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              deadnix.enable = true;
              nixfmt-rfc-style.enable = true;
            };
          };
          formatting = treefmtEval.config.build.check self;
        };
        packages = import ./packages { inherit pkgs; };
        overlays = import ./overlays {
          inherit pkgs-unstable;
          inherit my-pkgs;
          inherit (inputs) nur;
        };
        devShells.default = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        };
      }
    )
    // {
      templates = {
        minimalDevShell = {
          path = ./templates/minimal-dev-shell;
          description = "A flake with a minimal dev shell for all systems";
        };
      };
      homeConfigurations."benedikt" = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          inputs.catppuccin.homeModules.catppuccin
          inputs.nixvim.homeManagerModules.nixvim
          ./home/benedikt.nix
          (
            { pkgs, lib, ... }:
            {
              nixpkgs.overlays = [
                (_self: _super: {
                  gh-get = pkgs.callPackage ./packages/gh-get { };
                })
              ];
              nixpkgs.config.allowUnfreePredicate =
                pkg:
                builtins.elem (lib.getName pkg) [
                  "terraform"
                  "claude-code"
                ];

            }
          )
        ];

        extraSpecialArgs = {
          osConfig.my.user = {
            fullName = "Benedikt Ritter";
            email = "benedikt.ritter@chainguard.dev";
            signingKey = "EA363E64382563CF";
          };
        };
      };
    }
    // lib.defineSystems inputs;
}
