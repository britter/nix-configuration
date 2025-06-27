_: {
  programs.nixvim = {
    plugins.tmux-navigator.enable = true;
    keymaps = [
      # Jump through and delete buffers
      {
        action = "<cmd>bprev<CR>";
        key = "[b";
        mode = [ "n" ];
      }
      {
        action = "<cmd>bnext<CR>";
        key = "]b";
        mode = [ "n" ];
      }
      {
        action = "<cmd>bdelete<CR>";
        key = "<leader>bd";
        mode = [ "n" ];
      }
      # Jump through quickfix list
      {
        action = "<cmd>cprevious<CR>";
        key = "[q";
        mode = [ "n" ];
      }
      {
        action = "<cmd>cnext<CR>";
        key = "]q";
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
