{
  lib,
  inputs,
  ...
}: {
  options.my = with lib; {
    host = {
      name = mkOption {
        type = types.str;
      };
      system = mkOption {
        type = types.enum inputs.flake-utils.lib.allSystems;
      };
      ip = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      role = mkOption {
        type = types.enum ["desktop" "server"];
        description = "The role this machine has";
      };
      profiles = mkOption {
        type = types.listOf (types.enum ["private" "work"]);
        description = "The profiles to enable on this host";
        default = [];
      };
    };
    user = {
      name = mkOption {
        type = types.str;
        default = "bene";
      };
      fullName = mkOption {
        type = types.str;
        default = "Benedikt Ritter";
      };
      email = mkOption {
        type = types.str;
        default = "beneritter@gmail.com";
      };
      signingKey = mkOption {
        type = types.str;
      };
    };
    modules.allowedUnfreePkgs = mkOption {
      type = types.listOf types.str;
      default = [];
    };
  };
}
