{
  description = "A flake for managing my machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    # master is required to get the latest packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    nix-darwin,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      formatter = pkgs.alejandra;
      packages = import ./packages {inherit pkgs;};
    })
    // {
      nixosConfigurations.latitue-7280 = let
        system = flake-utils.lib.system.x86_64-linux;
      in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            {
              nixpkgs.overlays = [
                (final: prev: {
                  jdt-language-server = nixpkgs-unstable.legacyPackages.${system}.jdt-language-server;
                })
              ];
            }
            ./hosts/latitute-7280/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.bene = {
                home.stateVersion = "23.05";
                imports = [./home.nix];
              };
            }
          ];
        };
      nixosConfigurations.pi-hole = let
        system = flake-utils.lib.system.aarch64-linux;
      in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/pi-hole/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.nixos = {
                home.stateVersion = "23.05";
                imports = [./pi-home.nix];
              };
            }
          ];
        };
      darwinConfigurations.WQ0C6FWJ1W = let
        system = flake-utils.lib.system.aarch64-darwin;
      in
        nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./hosts/work-macbook/configuration.nix
            {
              nixpkgs.overlays = [
                (final: prev: {
                  jdt-language-server = nixpkgs-unstable.legacyPackages.${system}.jdt-language-server;
                })
              ];
            }
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.bene = {
                home.stateVersion = "23.05";
                imports = [./work-home.nix];
              };
            }
          ];
        };
    };
}
