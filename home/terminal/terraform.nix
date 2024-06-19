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
    package = lib.mkPackageOption pkgs "terraform" {};
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    programs.helix.extraPackages = with pkgs; [
      terraform-ls
    ];
  };
}
