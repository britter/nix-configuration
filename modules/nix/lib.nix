{ config, inputs, ... }:
{
  flake.lib = rec {
    home-lab = import ../../home-lab.nix;
    mkNixos = system: hostName: {
      ${hostName} = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit
            inputs
            system
            hostName
            home-lab
            ;
        };
        modules = [
          inputs.self.modules.nixos.${hostName}
        ];
      };
    };
    mkHomeManager =
      system: name: extraSpecialArgs:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.self.overlays.default ];
          config.allowUnfreePackages = config.flake.allowUnfreePackages;
        };
        modules = [
          inputs.self.modules.homeManager.${name}
        ];
        extraSpecialArgs = extraSpecialArgs // {
          inherit inputs home-lab;
        };
      };
  };
}
