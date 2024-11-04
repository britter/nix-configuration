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
        "v" = "nvim (${pkgs.fzf}/bin/fzf)";
      };
    };
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      colorschemes.catppuccin = {
        enable = true;
        settings = {
          flavour = "macchiato";
        };
      };
      opts = {
        number = true;
        relativenumber = true;

        cursorline = true;
        scrolloff = 5;

        swapfile = false;

        list = true;
        listchars = "tab:→·,lead:·,space:·,trail:~,extends:→,precedes:←,nbsp:␣";
      };
      globals.mapleader = " ";
      plugins = {
        bufferline.enable = true;
        cmp.enable = true;
        lazygit.enable = true;
        lightline.enable = true;
        telescope.enable = true;
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
