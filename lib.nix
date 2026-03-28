let
  home-lab = {
    hosts = {
      srv-prod-2 = {
        ip = "192.168.30.12";
        dns = "srv-prod-2.ritter.family";
        vm = true;
      };
      srv-prod-3 = {
        ip = "192.168.30.13";
        dns = "srv-prod-3.ritter.family";
        vm = true;
      };
      srv-offsite-1 = {
        dns = "srv-offsite-1.ritter.family";
        vm = false;
      };
      directions = {
        ip = "192.168.5.6";
        dns = "directions.ritter.family";
        vm = false;
      };
      home-assistant = {
        ip = "192.168.20.234";
        dns = "homeassistant.ritter.family";
        vm = false;
      };
    };
    hypervisors = {
      pve = {
        ip = "192.168.5.10";
        dns = "pve.ritter.family";
        vm = false;
      };
    };
    devices = {
      fritz-box = {
        ip = "192.168.178.1";
        dns = "fritz-box.ritter.family";
        vm = false;
      };
      jetkvm = {
        ip = "100.96.211.6";
        dns = "jetkvm.ritter.family";
        vm = false;
      };
    };
  };
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
            inherit home-lab;
          };
          modules = [
            ./systems/${system}/${hostName}/configuration.nix
          ];
        };
      configurationAttrs =
        arch:
        builtins.map (hostName: {
          name = hostName;
          value = nixosConfiguration arch hostName;
        }) (builtins.attrNames systems.${arch});
      nixosConfigurations = builtins.listToAttrs (
        configurationAttrs "aarch64-linux" ++ configurationAttrs "x86_64-linux"
      );
    in
    {
      inherit nixosConfigurations;
    };
  lib = {
    inherit defineSystems;
    inherit home-lab;
  };
in
lib
