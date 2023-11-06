{pkgs, ...}: {
  home.packages = with pkgs; [
    exa # ls replacement
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
      "ls" = "exa";
      "ll" = "exa -la";
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
