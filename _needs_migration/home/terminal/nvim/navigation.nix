_: {
  programs.nixvim = {
    plugins.tmux-navigator.enable = true;
    keymaps = [
      {
        action = "<cmd>bdelete<CR>";
        key = "<leader>bd";
        mode = [ "n" ];
      }
      # Remap Crtl-d and Crtl-z to also center the view
      {
        action = "<C-d>zz";
        key = "<C-d>";
        mode = [ "n" ];
      }
      {
        action = "<C-u>zz";
        key = "<C-u>";
        mode = [ "n" ];
      }
      # Remap jumping trough search results to also center the view
      {
        action = "nzz";
        key = "n";
        mode = [ "n" ];
      }
      {
        action = "Nzz";
        key = "N";
        mode = [ "n" ];
      }
    ];
  };
}
