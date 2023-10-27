{
  description = "A flake for managing my machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin } : {
    nixosConfigurations.latitue-7280 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/latitute-7280/configuration.nix
        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.bene = {
            home.stateVersion = "23.05";
            imports = [ ./home.nix ];
          };
        }
      ];
    };
    darwinConfigurations.work-macbook = nix-darwin.lib.darwinSystem {
      system = "aarch64_darwin";
      modules = [
        ./hosts/work-macbook/configuration.nix
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.bene = {
            home.stateVersion = "23.05";
            imports = [ ./work-home.nix ];
          };
        }
      ];
    };
  };
}
