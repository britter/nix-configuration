{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.profiles.work;
in {
  options.my.home.profiles.work = {
    enable = lib.mkEnableOption "work-profile";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = with pkgs; {
      JDK8 = jdk8;
      JDK11 = jdk11;
      JDK17 = jdk17;
      JDK20 = jdk20;
      JDK21 = jdk21;
    };

    home.packages = with pkgs; [
      awscli2
      k3d
      kubernetes-helm
      kustomize
      shellcheck
    ];

    programs.fish.shellAliases = {
      dive = "docker run -ti --rm  -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive";
    };
  };
}
