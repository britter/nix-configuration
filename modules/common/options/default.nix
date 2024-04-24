{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.my = {
    host = {
      name = lib.mkOption {
        type = lib.types.str;
      };
      system = lib.mkOption {
        type = lib.types.enum inputs.flake-utils.lib.allSystems;
      };
      role = lib.mkOption {
        type = lib.types.enum ["desktop" "server"];
        description = "The role this machine has";
      };
    };
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "bene";
      };
      fullName = lib.mkOption {
        type = lib.types.str;
        default = "Benedikt Ritter";
      };
    };
  };
}