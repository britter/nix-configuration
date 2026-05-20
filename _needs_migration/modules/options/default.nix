{
  lib,
  system,
  hostName,
  ...
}:
{
  options.my = with lib; {
    host = {
      name = mkOption {
        type = types.str;
        default = hostName;
      };
      system = mkOption {
        type = types.enum [
          "x86_64-linux"
          "aarch64-linux"
        ];
        default = system;
      };
      role = mkOption {
        type = types.enum [
          "desktop"
          "server"
        ];
        description = "The role this machine has";
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
  };
}
