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
    ./lsp.nix
    ./navigation.nix
    ./ui.nix
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
      clipboard.providers.wl-copy.enable = true;
      # Add this to plugins below once switching to 24.11
      globals.mapleader = " ";
      opts = {
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

        swapfile = false;
      };
      autoCmd = [
        {
          event = ["BufNewFile" "BufRead"];
          pattern = ["*.java" "*.kt" "*.kts" "*.groovy"];
          callback.__raw =
            # lua
            ''
              function ()
                vim.opt_local.tabstop = 4
                vim.opt_local.softtabstop = 4
              end
            '';
        }
        {
          event = ["BufNewFile" "BufRead"];
          pattern = ["*.go"];
          callback.__raw =
            # lua
            ''
              function ()
                vim.opt_local.expandtab = false
              end
            '';
        }
        {
          event = ["BufNewFile" "BufRead"];
          pattern = ["*.log"];
          callback.__raw =
            # lua
            ''
              function ()
                vim.opt_local.wrap = false
              end
            '';
        }
      ];
      keymaps = [
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
        {
          action = "<cmd>split<CR>";
          key = "<leader>\"";
          mode = ["n"];
        }
        {
          action = "<cmd>vsplit<CR>";
          key = "<leader>%";
          mode = ["n"];
        }
      ];
      plugins = {
        telescope = {
          enable = true;
          extensions.ui-select.enable = true;
        };
        treesitter = {
          enable = true;
          indent = true;
        };
      };
    };
  };
}
