{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.java;
in {
  imports = [
    ./helix-java-support.nix
  ];

  options.my.home.java = {
    enable = lib.mkEnableOption "java";
  };

  config = lib.mkIf cfg.enable {
    programs.java = {
      enable = true;
      package = pkgs.jdk21;
    };

    programs.gradle = {
      enable = true;
      settings = {
        "org.gradle.java.installations.paths" = "${pkgs.jdk8},${pkgs.jdk11}";
      };
    };

    my.home.helix-java-support.enable = true;
  };
}
