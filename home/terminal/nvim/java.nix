{
  lib,
  pkgs,
  ...
}:
{
  programs.nixvim.plugins.nvim-jdtls = {
    enable = true;
    cmd = [
      (lib.getExe pkgs.jdt-language-server)
    ];
  };
  programs.git.ignores = [
    "bin/"
    ".classpath"
    ".project"
    ".settings/"
  ];
}
