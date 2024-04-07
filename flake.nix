{
  description = "A flake for managing my machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    # unstable is required to get more up to date packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";

    disko = {
      url = "github:nix-community/disko";
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
    nixos-hardware,
    home-manager,
    catppuccin,
    disko,
    nix-darwin,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
    in {
      formatter = pkgs.alejandra;
      packages = import ./packages {inherit pkgs;};
      overlays = [
        (final: prev:
          {
            jdt-language-server = pkgs-unstable.jdt-language-server;
            jetbrains = pkgs-unstable.jetbrains;
          }
          // self.outputs.packages.${system})
      ];
    })
    // {
      nixosConfigurations.pulse-14 = let
        system = flake-utils.lib.system.x86_64-linux;
      in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            (import ./hosts/pulse-14/disko.nix {device = "/dev/nvme0n1";})
            {
              nixpkgs.overlays = self.overlays.${system};
            }
            ./hosts/pulse-14/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.bene = {
                home.stateVersion = "23.05";
                imports = [
                  catppuccin.homeManagerModules.catppuccin
                  ./home/latitude.nix
                ];
              };
            }
          ];
        };
      nixosConfigurations.latitude-7280 = let
        system = flake-utils.lib.system.x86_64-linux;
      in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            nixos-hardware.nixosModules.dell-latitude-7280
            disko.nixosModules.disko
            (import ./hosts/latitude-7280/disko.nix {device = "/dev/sda";})
            {
              nixpkgs.overlays = self.overlays.${system};
            }
            ./hosts/latitude-7280/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.bene = {
                home.stateVersion = "23.05";
                imports = [
                  catppuccin.homeManagerModules.catppuccin
                  ./home/latitude.nix
                ];
              };
            }
          ];
        };
      nixosConfigurations.raspberry-pi = let
        system = flake-utils.lib.system.aarch64-linux;
      in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            nixos-hardware.nixosModules.raspberry-pi-4
            {
              nixpkgs.overlays = self.overlays.${system};
            }
            ./hosts/raspberry-pi/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.nixos = {
                home.stateVersion = "23.05";
                imports = [
                  catppuccin.homeManagerModules.catppuccin
                  ./home/raspberry-pi.nix
                ];
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
            {
              nixpkgs.overlays = self.overlays.${system};
            }
            ./hosts/work-macbook/configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.bene = {
                home.stateVersion = "23.05";
                imports = [
                  catppuccin.homeManagerModules.catppuccin
                  ./home/work-macbook.nix
                ];
              };
            }
          ];
        };
    };
}
