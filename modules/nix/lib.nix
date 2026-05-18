{ inputs, ... }:
{
  flake.lib = rec {
    home-lab = import ./home-lab.nix;
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
  };
}
