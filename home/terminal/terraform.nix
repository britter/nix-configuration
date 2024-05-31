{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.terminal.terraform;
in {
  options.my.home.terminal.terraform = {
    enable = lib.mkEnableOption "terraform";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.terraform
    ];

    programs.helix.extraPackages = with pkgs; [
      terraform-ls
    ];
  };
}
