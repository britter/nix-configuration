let
  defineSystems =
    inputs:
    let
      systems = builtins.mapAttrs (k: _v: builtins.readDir ./systems/${k}) (builtins.readDir ./systems);
      nixosConfiguration =
        system: hostName:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit system;
            inherit hostName;
          };
          modules = [
            ./systems/${system}/${hostName}/configuration.nix
          ];
        };
      configurationAttrs =
        builder: arch:
        builtins.map (hostName: {
          name = hostName;
          value = builder arch hostName;
        }) (builtins.attrNames systems.${arch});
      nixosConfigurations =
        let
          nixosConfigurationAttrs = aarch: configurationAttrs nixosConfiguration aarch;
        in
        builtins.listToAttrs (
          nixosConfigurationAttrs "aarch64-linux" ++ nixosConfigurationAttrs "x86_64-linux"
        );
    in
    {
      inherit nixosConfigurations;
    };
  lib = {
    inherit defineSystems;
  };
in
lib
