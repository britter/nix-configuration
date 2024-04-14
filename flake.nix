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

  outputs = {self, ...} @ inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
      my-pkgs = self.outputs.packages.${system};
    in {
      formatter = pkgs.alejandra;
      packages = import ./packages {inherit pkgs;};
      overlays = import ./overlays {
        inherit pkgs-unstable;
        inherit my-pkgs;
      };
    })
    // {
      nixosConfigurations.pulse-14 = let
        system = inputs.flake-utils.lib.system.x86_64-linux;
      in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [
            ./hosts/pulse-14/configuration.nix
          ];
        };
      nixosConfigurations.latitude-7280 = let
        system = inputs.flake-utils.lib.system.x86_64-linux;
      in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/latitude-7280/configuration.nix
          ];
        };
      nixosConfigurations.raspberry-pi = let
        system = inputs.flake-utils.lib.system.aarch64-linux;
      in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [
            ./hosts/raspberry-pi/configuration.nix
          ];
        };
      darwinConfigurations.WQ0C6FWJ1W = let
        system = inputs.flake-utils.lib.system.aarch64-darwin;
      in
        inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./hosts/work-macbook/configuration.nix
          ];
        };
    };
}
