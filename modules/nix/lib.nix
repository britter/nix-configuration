{ config, inputs, ... }:
{
  flake.lib = rec {
    home-lab = import ../../home-lab.nix;
    mkNixos =
      system: hostName:
      inputs.nixpkgs.lib.nixosSystem {
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
          "${toString inputs.self}/systems/${system}/${hostName}/configuration.nix"
        ];
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
