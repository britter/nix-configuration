{
  description = "A flake for managing my machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    # unstable is required to get more up to date packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    catppuccin.url = "github:catppuccin/nix";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-terraform.url = "github:stackbuilders/nixpkgs-terraform";
  };

  outputs = {self, ...} @ inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
      my-pkgs = self.outputs.packages.${system};
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    in {
      formatter = treefmtEval.config.build.wrapper;
      checks = {
        formatting = treefmtEval.config.build.check self;
      };
      packages = import ./packages {inherit pkgs;};
      overlays = import ./overlays {
        inherit pkgs-unstable;
        inherit my-pkgs;
        inherit (inputs) nur;
        inherit (inputs) nixpkgs-terraform;
      };
    })
    // {
      # -----------------------------------------------------------------------
      # Desktops
      # -----------------------------------------------------------------------
      nixosConfigurations.pulse-14 = let
        system = inputs.flake-utils.lib.system.x86_64-linux;
      in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [
            ./systems/x86_64-linux/pulse-14/configuration.nix
          ];
        };
      nixosConfigurations.latitude-7280 = let
        system = inputs.flake-utils.lib.system.x86_64-linux;
      in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [
            ./systems/x86_64-linux/latitude-7280/configuration.nix
          ];
        };
      # -----------------------------------------------------------------------
      # Servers
      # -----------------------------------------------------------------------
      nixosConfigurations.directions = let
        system = inputs.flake-utils.lib.system.aarch64-linux;
      in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [
            ./systems/aarch64-linux/directions/configuration.nix
          ];
        };
      nixosConfigurations.srv-prod-1 = let
        system = inputs.flake-utils.lib.system.x86_64-linux;
      in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [
            ./systems/x86_64-linux/srv-prod-1/configuration.nix
          ];
        };
      nixosConfigurations.srv-prod-2 = let
        system = inputs.flake-utils.lib.system.x86_64-linux;
      in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [
            ./systems/x86_64-linux/srv-prod-2/configuration.nix
          ];
        };
      # -----------------------------------------------------------------------
      # ISOs
      # -----------------------------------------------------------------------
      nixosConfigurations.minimalServerIso = let
        system = inputs.flake-utils.lib.system.x86_64-linux;
      in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [
            ./systems/x86_64-linux/minimal-server-iso/configuration.nix
          ];
        };
      # -----------------------------------------------------------------------
      # Darwin
      # -----------------------------------------------------------------------
      darwinConfigurations.WQ0C6FWJ1W = let
        system = inputs.flake-utils.lib.system.aarch64-darwin;
      in
        inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [
            ./systems/aarch64-darwin/work-macbook/configuration.nix
          ];
        };
    };
}
