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
        default = "server";
        description = "The role this machine has";
      };
    };
  };
}
