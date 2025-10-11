_: {
  programs.nixvim = {
    plugins = {
      # git integration
      fugitive.enable = true;
      # GitHub integration, enabling :GBrowse
      rhubarb.enable = true;
      gitsigns = {
        enable = true;
      };
      lazygit.enable = true;
    };
    keymaps = [
      {
        action = "<cmd>LazyGit<CR>";
        key = "<leader>gg";
        mode = [ "n" ];
        options = {
          silent = true;
        };
      }
      {
        action = "<cmd>LazyGitFilter<CR>";
        key = "<leader>gl";
        mode = [ "n" ];
        options = {
          silent = true;
        };
      }
      {
        action = "<cmd>LazyGitFilterCurrentFile<CR>";
        key = "<leader>glf";
        mode = [ "n" ];
        options = {
          silent = true;
        };
      }
      {
        action = "<cmd>Git blame<CR>";
        key = "<leader>gb";
        mode = [ "n" ];
      }
      {
        action = "<cmd>Gitsigns prev_hunk<CR>";
        key = "[g";
        mode = [ "n" ];
      }
      {
        action = "<cmd>Gitsigns next_hunk<CR>";
        key = "]g";
        mode = [ "n" ];
      }
      {
        action = "<cmd>Gitsigns preview_hunk<CR>";
        key = "<leader>gp";
        mode = [ "n" ];
      }
      {
        action = "<cmd>Gitsigns reset_hunk<CR>";
        key = "<leader>gr";
        mode = [ "n" ];
      }
    ];
  };
}
