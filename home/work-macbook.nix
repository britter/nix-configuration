{pkgs, ...}: {
  home.sessionVariables = with pkgs; {
    JDK8 = jdk8;
    JDK11 = jdk11;
    JDK17 = jdk17;
    JDK20 = jdk20;
    JDK21 = jdk21;
  };

  home.packages = with pkgs; [
    terraform
  ];

  programs.helix.extraPackages = with pkgs; [
    terraform-ls
  ];

  programs.fish.shellAliases = {
    dive = "docker run -ti --rm  -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive";
  };
}
