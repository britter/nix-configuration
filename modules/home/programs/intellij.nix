_: {
  flake.modules.homeManager.intellij =
    { lib, pkgs, ... }:
    let
      idea = pkgs.jetbrains.idea-oss;
      ideaStartScript = pkgs.writeShellApplication {
        name = "idea";
        text = ''
          DIR=''${1:-$(pwd)}
          nohup ${lib.getExe idea} "$DIR" > /dev/null 2>&1 &
        '';
      };
    in
    {
      home.packages = [
        idea
        ideaStartScript
      ];
      programs.git.ignores = [
        ## IntelliJ stuff
        ".idea"
        "*.iml"
        "out/"
      ];
    };
}
