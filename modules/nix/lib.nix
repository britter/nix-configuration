{
  config,
  inputs,
  lib,
  ...
}:
{
  flake.lib = {
    # Derive a flake-root-relative path string from a Nix path literal.
    # Errors at eval time if the underlying file is missing.
    relativePath = path: lib.removePrefix "${inputs.self}/" (toString path);
    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          inputs.self.modules.nixos.${name}
          {
            networking.hostName = name;
            nixpkgs.hostPlatform = lib.mkDefault system;
          }
        ];
      };
    };
    mkHomeManager = system: name: {
      ${name} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.self.overlays.default ];
          config.allowUnfreePackages = config.flake.allowUnfreePackages;
        };
        modules = [
          inputs.self.modules.homeManager.${name}
        ];
        extraSpecialArgs = { inherit inputs; };
      };
    };
  };
}
