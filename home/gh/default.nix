{pkgs, ...}: {
  programs.gh = {
    enable = true;

    extensions = [pkgs.gh-get];
  };
}
