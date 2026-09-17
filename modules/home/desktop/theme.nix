{ inputs, ... }:
let
  # Shared by both halves: the NixOS one themes the console, GTK/Qt and the
  # greeter, the home-manager one every program a user configures. Hosts
  # without a desktop import only the home-manager half, so the settings
  # cannot live in the NixOS module alone.
  settings =
    { pkgs, ... }:
    {
      stylix = {
        enable = true;
        polarity = "dark";
        base16Scheme = ./theme/night-owl.yaml;

        # Consumed by the targets that set a wallpaper, noctalia among them.
        image = "${pkgs.wallpapers}/landscapes/tropic_island_night.jpg";

        cursor = {
          package = pkgs.adwaita-icon-theme;
          name = "Adwaita";
          size = 32;
        };

        fonts.monospace = {
          package = pkgs.nerd-fonts.fira-code;
          name = "FiraCode Nerd Font Mono";
        };
      };
    };
in
{
  flake.modules.nixos.theme = {
    imports = [
      inputs.stylix.nixosModules.stylix
      settings
    ];

    # Desktop users import the home-manager half through their own profile, so
    # the NixOS module must not push a second copy into
    # home-manager.sharedModules: stylix declares read-only options that cannot
    # be defined twice.
    stylix.homeManagerIntegration.autoImport = false;
  };

  flake.modules.homeManager.theme = {
    imports = [
      inputs.stylix.homeModules.stylix
      settings
    ];

    # On framework-13 home-manager runs with useGlobalPkgs, where nixpkgs
    # options declared inside a home-manager configuration have no effect. The
    # two packages stylix patches through an overlay are patched by the NixOS
    # half there anyway.
    stylix.overlays.enable = false;
  };
}
