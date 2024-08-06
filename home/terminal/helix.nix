{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.terminal.helix;
in {
  options.my.home.terminal.helix = {
    enable = lib.mkEnableOption "helix";
  };

  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      defaultEditor = true;
      extraPackages = with pkgs; [
        nil # Nix lsp
        taplo # TOML lsp
      ];
      settings = {
        editor = {
          bufferline = "multiple";
          file-picker.hidden = false;
          whitespace.render = {
            space = "all";
            nbsp = "all";
            tab = "all";
          };
        };
        keys.normal = {
          up = "no_op";
          down = "no_op";
          left = "no_op";
          right = "no_op";
          pageup = "no_op";
          pagedown = "no_op";
        };
      };
    };
  };
}
