{
  description = "A flake for managing my machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    # master is required to get the latest packages
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-master,
    home-manager,
    nix-darwin,
    ...
  }: {
    formatter = {
      x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.alejandra;
      aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
    };
    nixosConfigurations.latitue-7280 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [
            (final: prev: {
              jdt-language-server = nixpkgs-master.legacyPackages.x86_64-linux.jdt-language-server;
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
    nixosConfigurations.pi-hole = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
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
    darwinConfigurations.WQ0C6FWJ1W = nix-darwin.lib.darwinSystem {
      system = "aarch64_darwin";
      modules = [
        ./hosts/work-macbook/configuration.nix
        {
          nixpkgs.overlays = [
            (final: prev: {
              jdt-language-server = nixpkgs-master.legacyPackages.aarch64-darwin.jdt-language-server;
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
