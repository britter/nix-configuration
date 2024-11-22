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
        "org.gradle.java.installations.paths" = "${pkgs.jdk8.home},${pkgs.jdk11.home}";
      };
    };

    my.home.helix-java-support.enable = true;
  };
}
