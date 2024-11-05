{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.terminal.nvim;
in {
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
      colorschemes.gruvbox.enable = true;
      extraPlugins = [pkgs.vimPlugins."lightline-gruvbox-vim"];
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
        cmp.enable = true;
        gitsigns = {
          enable = true;
          settings.current_line_blame = true;
        };
        lazygit.enable = true;
        lightline.enable = true;
        lsp = {
          enable = true;
          servers = {
            nixd.enable = true;
          };
        };
        telescope.enable = true;
        treesitter.enable = true;
      };
      keymaps = [
        {
          action = "<cmd>LazyGit<CR>";
          key = "<leader>gg";
          mode = ["n"];
          options = {
            silent = true;
          };
        }
        {
          action = "<cmd>LazyGitFilter<CR>";
          key = "<leader>gl";
          mode = ["n"];
          options = {
            silent = true;
          };
        }
        {
          action = "<cmd>LazyGitFilterCurrentFile<CR>";
          key = "<leader>glf";
          mode = ["n"];
          options = {
            silent = true;
          };
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
