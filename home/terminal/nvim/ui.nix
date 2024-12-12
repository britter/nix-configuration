_: {
  programs.nixvim = {
    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "macchiato";
      settings.integrations.treesitter = true;
      settings.integrations.gitsigns = true;
      settings.integrations.native_lsp.enabled = true;
      settings.integrations.neotree = true;
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
    plugins = {
      bufferline.enable = true;
      lualine.enable = true;
      markview.enable = true;
      neo-tree.enable = true;
      web-devicons.enable = true;
    };
    keymaps = [
      {
        action = "<cmd>Neotree filesystem reveal toggle left<CR>";
        key = "<C-n>";
        mode = ["n"];
      }
    ];
  };
}
