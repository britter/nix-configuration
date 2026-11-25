{ inputs, ... }:
{
  flake.modules.nixos.yubikey-provision-iso =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      ];

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      environment.systemPackages = with pkgs; [
        age
        age-plugin-yubikey
        git
        neovim
        sops
        ssh-to-age
        yubikey-manager
      ];

      environment.variables.EDITOR = lib.getExe pkgs.neovim;

      services.pcscd.enable = true;
      services.udev.packages = [ pkgs.yubikey-personalization ];
    };
}
