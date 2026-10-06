{ config, ... }:
{
  flake.modules.nixos.garage-on-srv-prod-3 =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [ garage ];

      services.garage.settings.metadata_dir = "/mnt/data/garage/meta";
      services.garage.settings.data_dir = "/mnt/data/garage/data";
    };
}
