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
    home.packages =
      lib.optionals config.my.home.profiles.private.enable [pkgs.terraform]
      ++ lib.optionals config.my.home.profiles.work.enable [pkgs.terraform-versions."1.4.6"];

    programs.helix.extraPackages = with pkgs; [
      terraform-ls
    ];
  };
}
