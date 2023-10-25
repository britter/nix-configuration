{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nil # Nix lsp
    taplo # TOML lsp
  ];

  home.sessionVariables = {
    # See below, this can be replaces with programs.helix.defaultEditor in the next home-manager release
    EDITOR = "hx";
  };

  programs.helix = {
    enable = true;
    # defaultEditor is a setting in home-manager master. Comment out once updated to next home-manager release
    # defaultEditor = true;
    settings = {
      theme = "catppuccin_macchiato";
      editor.file-picker = {
        hidden = false;
      };
      editor.whitespace.render = {
        space = "all";
        nbsp = "all";
        tab = "all";
      };
      keys.normal = {
        up = "no_op";
        down = "no_op";
        left = "no_op";
        right = "no_op";
        pageup = "no_op";
        pagedown = "no_op";
      };
    };
  };
}
