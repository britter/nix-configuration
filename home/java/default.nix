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
    ../gradle
  ];

  options.my.home.java = {
    enable = lib.mkEnableOption "java";
  };

  config = lib.mkIf cfg.enable {
    programs.java = {
      enable = true;
      package = pkgs.jdk21;
    };

    programs.gradle.enable = true;
  };
}
