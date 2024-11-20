_: {
  programs.nixvim = {
    plugins.tmux-navigator.enable = true;
    keymaps = [
      {
        action = "<cmd>bprev<CR>";
        key = "[b";
        mode = ["n"];
      }
      {
        action = "<cmd>bnext<CR>";
        key = "]b";
        mode = ["n"];
      }
      {
        action = "<cmd>bdelete<CR>";
        key = "bd";
        mode = ["n"];
      }
    ];
  };
}
