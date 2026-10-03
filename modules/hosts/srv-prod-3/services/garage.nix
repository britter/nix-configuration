{ config, ... }:
{
  flake.modules.nixos.garage-on-srv-prod-3 =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [ garage ];
    };
}
