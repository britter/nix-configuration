_: {
  flake.modules.nixos.system-desktop =
    { pkgs, ... }:
    {
      fonts.packages = [
        pkgs.font-awesome
        pkgs.nerd-fonts.fira-code
      ];
    };
}
