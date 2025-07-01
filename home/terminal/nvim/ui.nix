{ pkgs, ... }:
{
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
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "webify";
        src = pkgs.fetchFromGitHub {
          owner = "pabloariasal";
          repo = "webify.nvim";
          rev = "69bc088e21834898477df69694ce86ee5561e20b";
          hash = "sha256-Q9tJeo281JhEhjtxrh9BMzFfVQhJSZ3XShX4Agi6+1s=";
        };
      })
    ];
    extraConfigLua =
      # lua
      ''
        require('webify')
      '';
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
      oil.enable = true;
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
