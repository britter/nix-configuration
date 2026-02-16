{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.home.java;
in
{
  options.my.home.java = {
    enable = lib.mkEnableOption "java";
    version = lib.mkOption {
      type = lib.types.int;
      default = "21";
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

  config =
    let
      allVersions = lib.map toString (cfg.additionalVersions ++ [ cfg.version ]);
      jdkPackageForVersion = version: pkgs."jdk${version}";
      javaHomeForVersion = version: (jdkPackageForVersion version).home;
    in
    lib.mkIf cfg.enable {
      home.sessionVariables = lib.mapAttrs' (name: value: lib.nameValuePair ("JDK_" + name) value) (
        lib.genAttrs allVersions javaHomeForVersion
      );

      programs.java = {
        enable = true;
        package = pkgs."jdk${toString cfg.version}";
      };

      systemd.user.tmpfiles.rules = lib.mkIf cfg.linkToUserHome (
        lib.map (
          v:
          let
            pkg = jdkPackageForVersion v;
          in
          "L ${config.home.homeDirectory}/.java-installs/${pkg.name} - - - - ${pkg}"
        ) allVersions
      );

      programs.gradle = {
        enable = true;
        settings = {
          "org.gradle.java.installations.paths" = lib.concatStringsSep "," (
            lib.map javaHomeForVersion allVersions
          );
          "systemProp.jna.library.path" = lib.makeLibraryPath [ pkgs.udev ];
        };
      };
      programs.nixvim.plugins.jdtls.settings.settings.java.configuration.runtimes = lib.map (v: {
        name = "JavaSE-${v}";
        path = javaHomeForVersion v;
      }) allVersions;
    };
}
