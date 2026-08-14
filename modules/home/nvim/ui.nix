_: {
  flake.modules.homeManager.nvim = { pkgs, ... }: {
    programs.nixvim = {
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
        web-devicons.enable = true;
      };
      extraPlugins = [ pkgs.vimPlugins.nvim-pqf ];
      extraConfigLua =
        #lua
        ''
          require('pqf').setup()
        '';
    };
  };
}
