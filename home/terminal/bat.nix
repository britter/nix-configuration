{pkgs, ...}: {
  programs.bat = {
    enable = true;
    catppuccin = {
      enable = true;
      flavour = "macchiato";
    };
  };
}
