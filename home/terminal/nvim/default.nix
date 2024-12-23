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
        # Set tab width to 4 spaces (instead of 8)
        tabstop = 4;
        # Set how many spaces will be inserted when tab is pressed
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
      filetype.extension = {
        log = "log";
      };
      files = {
        "ftplugin/astro.lua" = {
          opts = {
            softtabstop = 4;
            shiftwidth = 4;
          };
        };
        "ftplugin/java.lua" = {
          opts = {
            softtabstop = 4;
            shiftwidth = 4;
          };
        };
        "ftplugin/kotlin.lua" = {
          opts = {
            softtabstop = 4;
            shiftwidth = 4;
          };
        };
        "ftplugin/groovy.lua" = {
          opts = {
            softtabstop = 4;
            shiftwidth = 4;
          };
        };
        "ftplugin/go.lua" = {
          opts = {
            expandtab = false;
            # Align tab width with what is being inserted when pressing tab
            softtabstop = 4;
            shiftwidth = 4;
          };
        };
        "ftplugin/log.lua" = {
          opts = {
            wrap = false;
          };
        };
      };
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
          action = "<cmd>Telescope lsp_document_symbols<CR>";
          key = "<leader>o";
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
        none-ls = {
          enable = true;
          sources = {
            formatting = {
              gofmt.enable = true;
              prettier = {
                enable = true;
                disableTsServerFormatter = true;
              };
              terraform_fmt.enable = true;
            };
          };
        };
        telescope = {
          enable = true;
          extensions.ui-select.enable = true;
        };
        treesitter = {
          enable = true;
          settings = {
            indent.enable = true;
            highlight.enable = true;
          };
        };
      };
    };
  };
}
