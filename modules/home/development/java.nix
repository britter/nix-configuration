_: {
  flake.modules.homeManager.java =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      allVersions = lib.map toString (config.java.additionalVersions ++ [ config.java.version ]);
      jdkPackageForVersion = version: pkgs."jdk${version}";
      javaHomeForVersion = version: (jdkPackageForVersion version).home;
    in
    {
      home.sessionVariables = lib.mapAttrs' (name: value: lib.nameValuePair ("JDK_" + name) value) (
        lib.genAttrs allVersions javaHomeForVersion
      );

      programs.java = {
        enable = true;
        package = pkgs."jdk${toString config.java.version}";
      };

      systemd.user.tmpfiles.rules = lib.mkIf config.java.linkToUserHome (
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
        package = pkgs.gradle_9;
        settings = {
          "org.gradle.java.installations.paths" = lib.concatStringsSep "," (
            lib.map javaHomeForVersion allVersions
          );
          "systemProp.jna.library.path" = lib.makeLibraryPath [ pkgs.udev ];
        };
      };
    };

}
