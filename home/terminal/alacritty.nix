{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      font.normal.family = "FiraCode Nerd Font";
      shell = {
        program = "${pkgs.tmux}/bin/tmux";
        args =[ "new-session" "-A" "-D" "-s" "default"];
      };
    };
  };
}
