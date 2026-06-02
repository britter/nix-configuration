{
  lib,
  ...
}:
{
  options.my = with lib; {
    host = {
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
