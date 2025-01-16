{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.java;
in {
  options.my.home.java = {
    enable = lib.mkEnableOption "java";
    version = lib.mkOption {
      type = lib.types.int;
      default = "21";
    };
    additionalVersions = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [];
    };
  };

  config = let
    allVersions = lib.map toString (cfg.additionalVersions ++ [cfg.version]);
    versionToHome = version: pkgs."jdk${version}".home;
  in
    lib.mkIf cfg.enable {
      home.sessionVariables =
        lib.mapAttrs' (name: value: lib.nameValuePair ("JDK_" + name) value)
        (lib.genAttrs allVersions versionToHome);

      programs.java = {
        enable = true;
        package = pkgs."jdk${toString cfg.version}";
      };

      programs.gradle = {
        enable = true;
        settings = {
          "org.gradle.java.installations.paths" = lib.concatStringsSep "," (lib.map versionToHome allVersions);
          "systemProp.jna.library.path" = lib.makeLibraryPath [pkgs.udev];
        };
      };
    };
}
