{ inputs, ... }: {
  flake.modules.homeManager.nvim =
    {
      config,
      lib,
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
      };
    };
}
