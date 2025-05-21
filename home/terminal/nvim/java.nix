{
  lib,
  pkgs,
  ...
}:
{
  programs.nixvim.plugins.jdtls = {
    enable = true;
    settings.cmd = [
      (lib.getExe pkgs.jdt-language-server)
    ];
  };
  programs.git.ignores = [
    "bin/"
    ".classpath"
    ".project"
    ".settings/"
    ".factorypath"
  ];
}
