{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.gradle;
in {
  options.programs.gradle = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.gradle;
      defaultText = literalExpression "pkgs.gradle";
      example = "pkgs.gradle_7";
      description = ''
        The package to use for gradle.
      '';
    };
    javaPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = "pkgs.jdk17";
      description = ''
        The Java package to use for running Gradle.

        The default is not to use a dedicated Java package.
        Instead programs.java.enable = true will be configured which
        will result in JAVA_HOME being configured to that location.
        Gradle will then pick up that Java package.

        If a value is configured for this option it will be passed to
        Gradle by setting the org.gradle.java.home property in
        ~/.gradle/gradle.properties.
      '';
    };
    additionalJavaPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      example = "[ pkgs.jdk8 pkgs.jdk11 ]";
      description = ''
        Additional Java packages to make available to Gradle's Java toolchain infrastructure.
        The configured packages will be made available by setting the org.gradle.java.installations.paths
        property in ~/.gradle/gradle.properties.
      '';
    };
    gradleProperties = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = {
        "org.gradle.caching" = "true";
        "org.gradle.parallel" = "true";
        "org.gradle.jvmargs" = "-XX:MaxMetaspaceSize=384m";
      };
      description = ''
        Key value pairs to write to ~/.gradle/gradle.properties.
      '';
    };
    initScripts = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = {
        "maven-local.init.gradle" = ''
          allProject {
            repositories {
              mavenLocal()
            }
          }
        '';
      };
      description = ''
        Init script file names to init script file contents.
        The scripts will be linked in to the ~/.gradle/init.d directory.

        For more information including init script naming conventions
        see https://docs.gradle.org/current/userguide/init_scripts.html.
      '';
    };
  };

  config = let
    properties =
      concatStringsSep "\n"
      (mapAttrsToList (n: v: "${n}=${v}") (
        cfg.gradleProperties
        // optionalAttrs (cfg.javaPackage != null) {
          "org.gradle.java.home" = "${cfg.javaPackage}";
        }
        // optionalAttrs (length cfg.additionalJavaPackages > 0) {
          "org.gradle.java.installations.paths" = concatStringsSep "," (map toString cfg.additionalJavaPackages);
        }
      ));
    initScripts = pkgs.symlinkJoin {
      name = "gradle-init-scripts";
      paths = mapAttrsToList (name: content: pkgs.writeTextDir "init.d/${name}" content) cfg.initScripts;
    };
  in
    mkIf cfg.enable (
      mkMerge [
        {
          home.packages = [cfg.package];
          home.file.".gradle/init.d".source = "${initScripts}/init.d";
        }
        (mkIf (stringLength properties > 0) {
          home.file.".gradle/gradle.properties".text = properties;
        })
        (mkIf (cfg.javaPackage == null) {
          programs.java.enable = true;
        })
      ]
    );
}
