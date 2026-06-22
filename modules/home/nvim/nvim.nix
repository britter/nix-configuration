{ inputs, ... }: {
  flake.modules.homeManager.nvim =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.nixvim.homeModules.nixvim
      ];

      programs.fish = {
        shellAliases = {
          "v" = "nvim -c ':Telescope find_files'";
        };
      };
      home.sessionVariables = {
        MANPAGER = "${lib.getExe config.programs.nixvim.build.package} +Man!";
      };
      programs.nixvim = {
        enable = true;
        nixpkgs.useGlobalPackages = true;
        defaultEditor = true;
        clipboard.providers.wl-copy.enable = true;
        # Add this to plugins below once switching to 24.11
        globals.mapleader = " ";
        filetype.extension = {
          log = "log";
        };
        files = {
          "ftplugin/log.lua" = {
            opts = {
              wrap = false;
            };
          };
        };
        keymaps = [
          {
            action = "<ESC>";
            key = "jj";
            mode = [ "i" ];
          }
        ];
        plugins = {
          none-ls = {
            enable = true;
            sources = {
              formatting = {
                gofmt.enable = true;
                nixfmt = {
                  enable = true;
                  package = pkgs.nixfmt;
                };
                prettier = {
                  enable = true;
                  # should be removed once https://github.com/nix-community/nixvim/pull/4234 has been merged
                  package = pkgs.prettier;
                  disableTsServerFormatter = true;
                };
              };
              diagnostics.actionlint.enable = true;
            };
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
