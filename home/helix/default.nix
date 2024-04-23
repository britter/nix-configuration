{pkgs, ...}: {
  programs.helix = {
    enable = true;
    defaultEditor = true;
    extraPackages = with pkgs; [
      nil # Nix lsp
      taplo # TOML lsp
    ];
    settings = {
      theme = "catppuccin_macchiato";
      editor = {
        bufferline = "multiple";
        file-picker.hidden = false;
        whitespace.render = {
          space = "all";
          nbsp = "all";
          tab = "all";
        };
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
