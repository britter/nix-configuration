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
      profiles = lib.mkOption {
        type = lib.types.listOf (lib.types.enum ["private" "work"]);
        description = "The profiles to enable on this host";
        default = [];
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
      email = lib.mkOption {
        type = lib.types.str;
        default = "beneritter@gmail.com";
      };
      signingKey = lib.mkOption {
        type = lib.types.str;
      };
    };
  };
}
