{pkgs, ...}: {
  home.packages = with pkgs; [
    curl
    eza # ls replacement
    file
    httpie
    jq
    mob # smooth git handover
    tar
    tokei # count lines of code
    tldr # better man pages
    unzip
    wget
    zip
  ];
  programs.fzf.enable = true; # fuzzy finding
  programs.zoxide.enable = true; # smart cd replacement
}
