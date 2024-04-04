{pkgs, ...}: {
  programs.alacritty = let
    catpuccin-alacritty = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "alacritty";
      rev = "3c808cbb4f9c87be43ba5241bc57373c793d2f17";
      hash = "sha256-w9XVtEe7TqzxxGUCDUR9BFkzLZjG8XrplXJ3lX6f+x0=";
    };
  in {
    enable = true;
    settings = {
      import = ["${catpuccin-alacritty}/catppuccin-mocha.yml"];
      font.normal.family = "FiraCode Nerd Font";
      shell = {
        program = "${pkgs.tmux}/bin/tmux";
        args = ["new-session" "-A" "-D" "-s" "default"];
      };
    };
  };
}
