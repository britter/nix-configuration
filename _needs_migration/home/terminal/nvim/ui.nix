_: {
  programs.nixvim = {
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "macchiato";
        term_colors = true;
        integrations = {
          treesitter = true;
          gitsigns = true;
          native_lsp.enabled = true;
          neotree = true;
        };
      };
    };

    opts = {
      number = true;
      relativenumber = true;

      # Enable 24-bit colors
      termguicolors = true;

      # Enable the sign column to prevent the screen from jumping
      signcolumn = "yes";

      # Highlight cursor line
      cursorline = true;

      # Remaining lines visibile before starting to scroll
      scrolloff = 5;

      list = true;
      listchars = "tab:→·,lead:·,space:·,trail:~,extends:→,precedes:←,nbsp:␣";
    };
    # Show diagnostic as a virtual line but only below the current cursor line
    diagnostic.settings.virtual_lines.current_line = true;
    plugins = {
      dropbar.enable = true;
      lualine.enable = true;
      indent-blankline = {
        enable = true;
        settings.scope = {
          show_start = false;
          show_end = false;
        };
      };
      neo-tree.enable = true;
      oil = {
        enable = true;
        settings.skip_confirm_for_simple_edits = true;
      };
      web-devicons.enable = true;
    };
    keymaps = [
      {
        action = "<cmd>Neotree filesystem reveal toggle left<CR>";
        key = "<C-n>";
        mode = [ "n" ];
      }
      {
        action = "<cmd>Oil<CR>";
        key = "-";
        mode = [ "n" ];
      }
    ];
  };
}
