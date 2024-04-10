{pkgs, ...}: {
  programs.btop = {
    enable = true;
    catppuccin = {
      enable = true;
      flavour = "macchiato";
    };
  };

  # required for catppuccin theming of btop
  xdg.enable = true;
}
