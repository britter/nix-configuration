{ config, ... }:
{
  flake.modules.nixos.bene-on-framework-13 =
    { pkgs, ... }:
    {
      imports = with config.flake.modules.nixos; [
        bene
        sway
      ];

      # fix for Bitwarden client requiring deprecated electron version
      nixpkgs.config.permittedInsecurePackages = [
        "electron-39.8.10"
      ];

      home-manager.users.bene = {
        imports = [
          config.flake.modules.homeManager.sway
          ../../../_needs_migration/home/desktop
          ../../../_needs_migration/home/java
          ../../../_needs_migration/home/rust
        ];

        my.home = {
          desktop.enable = true;
          java = {
            enable = true;
            version = 25;
            additionalVersions = [
              8
              11
              17
              21
            ];
          };
          rust.enable = true;
        };

        user.signingKey = "394546A47BB40E12";

        services.kanshi = {
          enable = true;
          settings =
            let
              framework-13 = "BOE NE135A1M-NY1 Unknown";
              lg32 = "LG Electronics LG HDR 4K 111NTBKD6957";
            in
            [
              {
                profile.name = "home";
                profile.outputs = [
                  {
                    criteria = lg32;
                    status = "enable";
                    position = "0,0";
                  }
                  {
                    criteria = framework-13;
                    status = "enable";
                    position = "480,2160";
                  }
                ];
                profile.exec = [
                  "${pkgs.sway}/bin/swaymsg workspace 10, move workspace to eDP-1"
                  "${pkgs.sway}/bin/swaymsg workspace 1, move workspace to DP-2"
                ];
              }
            ];
        };
      };
    };
}
