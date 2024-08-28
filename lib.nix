let
  defineSystems = inputs: let
    systems = builtins.mapAttrs (k: _v: builtins.readDir ./systems/${k}) (builtins.readDir ./systems);
    configuration = builder: system: hostName:
      builder {
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
    configurationAttrs = builder: arch:
      builtins.map (hostName: {
        name = hostName;
        value = builder arch hostName;
      }) (builtins.attrNames systems.${arch});
    nixosConfiguration = arch: hostName:
      configuration inputs.nixpkgs.lib.nixosSystem arch hostName;
    nixosConfigurations = let
      nixosConfigurationAttrs = aarch: configurationAttrs nixosConfiguration aarch;
    in
      builtins.listToAttrs (nixosConfigurationAttrs "aarch64-linux" ++ nixosConfigurationAttrs "x86_64-linux");
    darwinConfiguration = arch: hostName:
      configuration inputs.nix-darwin.lib.darwinSystem arch hostName;
    darwinConfigurations = let
      darwinConfigurationAttrs = aarch: configurationAttrs darwinConfiguration aarch;
    in
      builtins.listToAttrs (darwinConfigurationAttrs "aarch64-darwin");
  in {
    inherit nixosConfigurations;
    inherit darwinConfigurations;
  };
  lib = {
    inherit defineSystems;
  };
in
  lib
