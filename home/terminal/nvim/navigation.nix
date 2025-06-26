_: {
  programs.nixvim = {
    plugins.tmux-navigator.enable = true;
    keymaps = [
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
    ];
  };
}
