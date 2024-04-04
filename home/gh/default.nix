{pkgs, ...}: {
  programs.gh = {
    enable = true;

    extensions = [pkgs.gh-get];

    settings = {
      git_protocol = "ssh";
    };
  };
}
