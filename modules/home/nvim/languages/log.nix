_: {
  flake.modules.homeManager.nvim = {
    programs.nixvim = {
      filetype.extension.log = "log";
      files."ftplugin/log.lua".opts.wrap = false;
    };
  };
}
