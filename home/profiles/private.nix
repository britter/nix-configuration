{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.profiles.private;
in {
  options.my.home.profiles.private = {
    enable = lib.mkEnableOption "private-profile";
  };

  config = lib.mkIf cfg.enable {
    programs.gradle = {
      settings = {
        "org.gradle.java.installations.paths" = "${pkgs.jdk8},${pkgs.jdk11}";
      };
    };
    programs.git = {
      includes = [
        {
          condition = "gitdir:~/github/gradlex-org/";
          contents = {
            user.email = "benedikt@gradlex.org";
            user.signingKey = "757DE51A2FD1489D";
          };
        }
        {
          condition = "gitdir:~/github/apache/";
          contents = {
            user.email = "britter@apache.org";
            user.signingKey = "9DAADC1C9FCC82D0";
          };
        }
      ];
    };
  };
}
