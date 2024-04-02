{pkgs, ...}: {
  programs.alacritty = let
    catpuccin-mocha = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/catppuccin/alacritty/main/catppuccin-mocha.yml";
      hash = "sha256-28Tvtf8A/rx40J9PKXH6NL3h/OKfn3TQT1K9G8iWCkM=";
    };
  in {
    enable = true;
    settings = {
      import = [catpuccin-mocha];
      font.normal.family = "FiraCode Nerd Font";
      shell = {
        program = "${pkgs.tmux}/bin/tmux";
        args = ["new-session" "-A" "-D" "-s" "default"];
      };
    };
  };
}
