{
  lib,
  pkgs,
  ...
}:
{
  programs.nixvim.plugins = {
    jdtls = {
      enable = true;
      settings.cmd = [
        (lib.getExe pkgs.jdt-language-server)
      ];
    };
    none-ls.luaConfig.post =
      # lua
      ''
        do
          local null_ls = require("null-ls")
          local helpers = require("null-ls.helpers")
          local root_dir = vim.fs.root(0, {'gradlew', '.git', 'mvnw'})
          -- use write with a to_temp_file. Otherwise, due to formatting being
          -- configured as an auto command on save in lsp.nix, nvim will call formatting
          -- before the file has written, replacing the contents with the formatting
          -- of the file on disk.
          -- jfmt also have a print command which prints the formatting result to the console
          -- but there's a quirk in none-ls' formatter_factory that enforces from_temp_file if
          -- to_temp_file is set to true.
          local args = {"write", "$FILENAME"}
          local config_file = vim.fs.joinpath(root_dir, 'gradle/config/eclipse-formatter.xml')
          if vim.uv.fs_stat(config_file) then
            table.insert(args, "--config-file")
            table.insert(args, config_file)
          end

          local jfmt = {
            method = null_ls.methods.FORMATTING,
            filetypes = { "java" },
            name = "jfmt",
            generator = helpers.formatter_factory({
              command = "${pkgs.jfmt-java}/bin/jfmt",
              to_temp_file = true,
              args = args,
            }),
          }
          null_ls.register(jfmt)
        end
      '';
  };
  programs.git.ignores = [
    "bin/"
    ".classpath"
    ".project"
    ".settings/"
    ".factorypath"
  ];
}
