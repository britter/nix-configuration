_: {
  flake.modules.homeManager.java-config = { lib, ... }: {
    options.java = {
      version = lib.mkOption {
        type = lib.types.int;
        default = 25;
      };
      additionalVersions = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ ];
      };
      linkToUserHome = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };
}
