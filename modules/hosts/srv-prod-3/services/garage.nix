{ config, ... }:
{
  flake.modules.nixos.garage-on-srv-prod-3 =
    { lib, ... }:
    {
      imports = with config.flake.modules.nixos; [ garage ];

      users.users.garage = {
        isSystemUser = true;
        group = "garage";
      };
      users.groups.garage = { };

      systemd.services.garage.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "garage";
        Group = "garage";
        StateDirectory = "garage";
        StateDirectoryMode = "0700";
        UMask = "0007";
      };

      systemd.tmpfiles.rules = [
        "d /mnt/data/garage/meta 0700 garage garage - -"
        "d /mnt/data/garage/data 0700 garage garage - -"
      ];

      services.garage.settings.metadata_dir = "/mnt/data/garage/meta";
      services.garage.settings.data_dir = "/mnt/data/garage/data";
    };
}
