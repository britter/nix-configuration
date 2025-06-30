{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.home.terminal.nvim;
in
{
  imports = [
    ./completion.nix
    ./git.nix
    ./java.nix
    ./lsp.nix
    ./navigation.nix
    ./ui.nix
    ./opentofu.nix
  ];

  options.my.home.terminal.nvim = {
    enable = lib.mkEnableOption "nvim";
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      shellAliases = {
        "v" =
          "nvim (${lib.getExe pkgs.fzf} --preview=\"${lib.getExe pkgs.bat} --style=numbers --color=always {}\")";
      };
    };
    programs.nixvim = {
      enable = true;
      nixpkgs.useGlobalPackages = true;
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
        "ftplugin/python.lua" = {
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
          mode = [ "n" ];
        }
        {
          action = "<cmd>Telescope live_grep<CR>";
          key = "<leader>fg";
          mode = [ "n" ];
        }
        {
          action = "<cmd>Telescope buffers<CR>";
          key = "<leader>fb";
          mode = [ "n" ];
        }
        {
          action = "<cmd>Telescope help_tag<CR>";
          key = "<leader>fh";
          mode = [ "n" ];
        }
        {
          action = "<cmd>split<CR>";
          key = "<leader>\"";
          mode = [ "n" ];
        }
        {
          action = "<cmd>vsplit<CR>";
          key = "<leader>%";
          mode = [ "n" ];
        }
      ];
      plugins = {
        nvim-surround.enable = true;
        none-ls = {
          enable = true;
          sources = {
            formatting = {
              gofmt.enable = true;
              nixfmt = {
                enable = true;
                package = pkgs.nixfmt-rfc-style;
              };
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
          extensions.fzf-native.enable = true;
          settings =
            let
              rgArgs = [
                "--hidden"
                "--glob"
                "!**/.git/*"
              ];
            in
            {
              defaults = {
                mappings = {
                  i = {
                    "<C-j>" = {
                      __raw = "require('telescope.actions').move_selection_next";
                    };
                    "<C-k>" = {
                      __raw = "require('telescope.actions').move_selection_previous";
                    };
                  };
                };
                vimgrep_arguments = [
                  (lib.getExe pkgs.ripgrep)
                  "--color=never"
                  "--no-heading"
                  "--with-filename"
                  "--line-number"
                  "--column"
                  "--smart-case"
                ] ++ rgArgs;
              };
              pickers.find_files.find_command = [
                (lib.getExe pkgs.ripgrep)
                "--files"
              ] ++ rgArgs;
            };
        };
        treesitter = {
          enable = true;
          settings = {
            indent.enable = true;
            highlight.enable = true;
          };
        };
        treesitter-context.enable = true;
      };
    };
  };
}
