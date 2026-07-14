_: {
  flake.modules.homeManager.fish =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        eza # ls replacement
        tokei # count lines of code
      ];

      programs.fish = {
        enable = true;

        shellAliases = {
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          "....." = "cd ../../../..";
          "cat" = "bat";
          "ls" = "eza";
          "ll" = "eza --all --long --icons=always --git";
          "tree" = "eza --tree --level=2";
          "loc" = "tokei";
          "tmp" = "cd (mktemp -d)";
        };

        shellInit = ''
          set -x LANG en_US.utf-8
          set -x GPG_TTY (tty)
        '';
      };
    };
}
