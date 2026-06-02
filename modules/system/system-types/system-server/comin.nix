{ inputs, ... }:
{
  flake.modules.nixos.system-server =
    { config, ... }:
    {
      imports = [ inputs.comin.nixosModules.comin ];

      services.comin = {
        enable = true;
        remotes = [
          {
            name = "origin";
            url = config.systemConstants.configRepo;
          }
        ];
      };
    };
}
