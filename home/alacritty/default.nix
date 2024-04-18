{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    catppuccin = {
      enable = true;
      flavour = "mocha";
    };
    settings = {
      font.normal.family = "FiraCode Nerd Font";
      shell = {
        program = "${pkgs.tmux}/bin/tmux";
        args = ["new-session" "-A" "-D" "-s" "default"];
      };
      window = {
        padding = {
          x = 20;
          y = 20;
        };
        opacity = 0.85;
        decorations = "None";
      };
    };
  };
}
