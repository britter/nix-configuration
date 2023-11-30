{pkgs, ...}: {
  home.packages = with pkgs; [
    eza # ls replacement
    mob # smooth git handover
    tokei # count lines of code
    tldr # better man pages
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
      "ll" = "eza -la";
      "loc" = "tokei";
    };

    shellInit = ''
      set -x LANG en_US.utf-8
      set -x MAVEN_OPTS "-Duser.name=benedikt"
      set -x GPG_TTY (tty)
    '';
  };

  programs.starship.enable = true; # prompt framework
  programs.bat.enable = true; # cat replacement
  programs.fzf.enable = true; # fuzzy finding
  programs.zoxide.enable = true; # smart cd replacement
}
