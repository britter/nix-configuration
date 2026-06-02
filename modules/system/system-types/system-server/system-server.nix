{ config, inputs, ... }:
{
  flake.modules.nixos.system-server = {
    imports = [
      config.flake.modules.nixos.system-base
      inputs.comin.nixosModules.comin
    ];

    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/britter/nix-configuration.git";
        }
      ];
    };
  };
}
