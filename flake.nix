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
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
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
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [
        ./modules/nix/dev-shell.nix
        ./modules/nix/lib.nix
        ./modules/nix/packages.nix
        ./modules/nix/pre-commit.nix
        ./modules/nix/overlays.nix
        ./modules/nix/templates.nix
        ./modules/nix/treefmt.nix

        ./modules/hosts/framework-13.nix
        ./modules/hosts/srv-prod-2.nix
        ./modules/hosts/srv-prod-3.nix
        ./modules/hosts/srv-prod-4.nix
        ./modules/hosts/srv-prod-5.nix
        ./modules/hosts/srv-offsite-1.nix
        ./modules/hosts/minimal-server-iso.nix
        ./modules/hosts/directions.nix
      ];
      flake = {
        homeConfigurations."benedikt" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [
            inputs.catppuccin.homeModules.catppuccin
            inputs.nixvim.homeModules.nixvim
            ./home/benedikt.nix
            (_: {
              nixpkgs.overlays = [
                inputs.self.overlays.default
              ];
              nixpkgs.config.allowUnfreePackages = [
                "terraform"
                "claude-code"
              ];
            })
          ];

          extraSpecialArgs = {
            osConfig.my.user = {
              fullName = "Benedikt Ritter";
              email = "benedikt.ritter@chainguard.dev";
              signingKey = "EA363E64382563CF";
            };
          };
        };
      };
    };
}
