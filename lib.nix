let
  home-lab = {
    hosts = {
      srv-prod-1 = {
        ip = "192.168.5.11";
        dns = "srv-prod-1.ritter.family";
        vm = true;
      };
      srv-prod-2 = {
        ip = "192.168.5.12";
        dns = "srv-prod-2.ritter.family";
        vm = true;
      };
      srv-prod-3 = {
        ip = "192.168.5.13";
        dns = "srv-prod-3.ritter.family";
        vm = true;
      };
      srv-test-1 = {
        ip = "192.168.5.21";
        dns = "srv-test-1.ritter.family";
        vm = true;
      };
      srv-test-2 = {
        ip = "192.168.5.22";
        dns = "srv-test-2.ritter.family";
        vm = true;
      };
      srv-eval-1 = {
        ip = "192.168.5.31";
        dns = "srv-eval-1.ritter.family";
        vm = true;
      };
      srv-backup-1 = {
        dns = "srv-backup-1.ritter.family";
        vm = false;
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
    inherit home-lab;
  };
in
lib
