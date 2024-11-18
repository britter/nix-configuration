{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.terminal.nvim;
in {
  imports = [
    ./completion.nix
    ./git.nix
    ./java.nix
  ];

  options.my.home.terminal.nvim = {
    enable = lib.mkEnableOption "nvim";
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      shellAliases = {
        "v" = "nvim (${pkgs.fzf}/bin/fzf --preview=\"${pkgs.bat}/bin/bat --style=numbers --color=always {}\")";
      };
    };
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      colorschemes.catppuccin = {
        enable = true;
        settings.flavour = "macchiato";
      };
      clipboard.providers.wl-copy.enable = true;
      # Add this to plugins below once switching to 24.11
      extraPlugins = [pkgs.vimPlugins."nvim-web-devicons"];
      opts = {
        number = true;
        relativenumber = true;

        # Set tabs to 2 spaces
        tabstop = 2;
        softtabstop = 2;
        showtabline = 2;
        expandtab = true;

        # Enable auto indenting and set it to spaces
        smartindent = true;
        shiftwidth = 2;

        # Enable smart indenting (see https://stackoverflow.com/questions/1204149/smart-wrap-in-vim)
        breakindent = true;

        # Enable 24-bit colors
        termguicolors = true;

        # Enable the sign column to prevent the screen from jumping
        signcolumn = "yes";

        # Highlight cursor line
        cursorline = true;

        # Remaining lines visibile before starting to scroll
        scrolloff = 5;

        swapfile = false;

        list = true;
        listchars = "tab:→·,lead:·,space:·,trail:~,extends:→,precedes:←,nbsp:␣";
      };
      globals.mapleader = " ";
      plugins = {
        bufferline.enable = true;
        lsp = {
          enable = true;
          servers = {
            nixd.enable = true;
            tsserver.enable = true;
          };
          keymaps = {
            lspBuf = {
              K = "hover";
              gd = "definition";
              "<leader>ca" = "code_action";
            };
            diagnostic = {
              "[d" = "goto_prev";
              "]d" = "goto_next";
              "<C-w>d" = "open_float";
            };
          };
        };
        lualine.enable = true;
        neo-tree.enable = true;
        telescope = {
          enable = true;
          extensions.ui-select.enable = true;
        };
        treesitter = {
          enable = true;
          indent = true;
        };
      };
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
        {
          action = "<cmd>Neotree filesystem reveal toggle left<CR>";
          key = "<C-n>";
          mode = ["n"];
        }
        {
          action = "<cmd>Telescope find_files<CR>";
          key = "<leader>ff";
          mode = ["n"];
        }
        {
          action = "<cmd>Telescope live_grep<CR>";
          key = "<leader>fg";
          mode = ["n"];
        }
        {
          action = "<cmd>Telescope buffers<CR>";
          key = "<leader>fb";
          mode = ["n"];
        }
      ];
    };
  };
}
