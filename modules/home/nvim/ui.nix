_: {
  flake.modules.homeManager.nvim = {
    programs.nixvim.plugins = {
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
  };
}
