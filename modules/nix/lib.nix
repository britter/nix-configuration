{
  config,
  inputs,
  lib,
  ...
}:
{
  flake.lib = rec {
    home-lab = import ../../home-lab.nix;
    # Derive a flake-root-relative path string from a Nix path literal.
    # Errors at eval time if the underlying file is missing.
    relativePath = path: lib.removePrefix "${inputs.self}/" (toString path);
    mkNixos = system: hostName: {
      ${hostName} = inputs.nixpkgs.lib.nixosSystem {
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
          {
            networking.hostName = hostName;
            nixpkgs.hostPlatform = lib.mkDefault system;
          }
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
