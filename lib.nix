let
  defineSystems = inputs: let
    systems = builtins.mapAttrs (k: _v: builtins.readDir ./systems/${k}) (builtins.readDir ./systems);
    defineNixosSystem = system: hostName:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit hostName;
          inherit system;
        };
        modules = [
          ./systems/${system}/${hostName}/configuration.nix
        ];
      };
    nixosConfigurations = let
      defineConfiguration = system:
        builtins.map (hostName: {
          name = hostName;
          value = defineNixosSystem system hostName;
        }) (builtins.attrNames systems.${system});
    in
      builtins.listToAttrs (defineConfiguration "aarch64-linux" ++ defineConfiguration "x86_64-linux");
  in {inherit nixosConfigurations;};
  lib = {
    inherit defineSystems;
  };
in
  lib
