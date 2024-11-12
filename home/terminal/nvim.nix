{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.home.terminal.nvim;
  # Workaround to set up a custom LSP because jdt-language-server was not available in 24.05
  # will be added with the 24.11 release, so this can be removed.
  # Source of this snippet: https://github.com/nix-community/nixvim/discussions/2011#discussioncomment-10782956
  mkLspModule = args:
  # Return a module function
  {
    pkgs,
    lib,
    config,
    ...
  }: let
    mkLsp' = import "${inputs.nixvim}/plugins/lsp/language-servers/_mk-lsp.nix" {inherit pkgs lib config;};
  in {programs.nixvim = mkLsp' args;};
in {
  imports = [
    (mkLspModule {
      name = "jdtls";
      description = "jdtls language server for Java";
      package = pkgs.jdt-language-server;
      cmd = _cfg: [
        "${pkgs.jdt-language-server}/bin/jdtls"
        "-configuration"
        "/build/.cache/jdtls/config"
        "-data"
        "/build/.cache/jdtls/workspace"
      ];
    })
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
        # Review the configuration for cmp after switching to 24.11
        cmp = {
          enable = true;
          autoEnableSources = true;
          settings = {
            mapping = {
              "<C-Space>" = "cmp.mapping.complete()";
              "<C-d>" = "cmp.mapping.scroll_docs(-4)";
              "<C-e>" = "cmp.mapping.close()";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
              "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            };
            snippet = {
              expand = "function(args) require('luasnip').lsp_expand(args.body) end";
            };
            sources = [
              {name = "nvim_lsp";}
              {name = "luasnip";}
              {name = "buffer";}
            ];
          };
        };
        cmp_luasnip.enable = true;
        luasnip = {
          enable = true;
          extraConfig = {
            enable_autosnippets = true;
            store_selection_keys = "<Tab>";
          };
          fromVscode = [{}];
        };
        friendly-snippets.enable = true;
        gitsigns = {
          enable = true;
          settings.current_line_blame = true;
        };
        lazygit.enable = true;
        lsp = {
          enable = true;
          servers = {
            jdtls.enable = true;
            nixd.enable = true;
            tsserver.enable = true;
          };
          keymaps.lspBuf = {
            K = "hover";
            gd = "definition";
            "<leader>ca" = "code_action";
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
          action = "<cmd>Gitsigns preview_hunk<CR>";
          key = "<leader>gp";
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
