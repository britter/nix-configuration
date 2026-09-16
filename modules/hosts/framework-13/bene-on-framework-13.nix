{ config, ... }:
{
  flake.modules.nixos.bene-on-framework-13 =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [
        bene
        forgejo-client
        nextcloud-client
        niri
      ];

      home-manager.users.bene = {
        imports = with config.flake.modules.homeManager; [
          niri
          ai-agents
          bitwarden
          calibre
          desktop-essentials
          forgejo-client
          ghostty
          intellij
          librewolf
          nextcloud-client
          obsidian
          syncthing
          java
          zoom
        ];

        java = {
          version = 25;
          additionalVersions = [
            8
            11
            17
            21
          ];
        };

        user.signingKey = "394546A47BB40E12";

        programs.git.includes = [
          {
            condition = "gitdir:~/github/gradlex-org/";
            contents.user.signingKey = "757DE51A2FD1489D";
          }
          {
            condition = "gitdir:~/github/apache/";
            contents.user.signingKey = "9DAADC1C9FCC82D0";
          }
          {
            condition = "gitdir:~/clients/";
            contents = {
              user.email = "benedikt.ritter@proton.me";
              user.signingKey = "F9190A44AEFC562C";
            };
          }
        ];

        programs.cargo.enable = true;
        programs.opencode.enable = true;

        # Outputs that are not connected are ignored, so this one static
        # layout covers both docked and undocked with no profile switching.
        # Workspaces remember which monitor they came from and migrate back
        # on reconnect on their own.
        wayland.windowManager.niri.settings._children =
          let
            # niri places outputs in logical pixels and lets the cursor cross
            # only between outputs whose edges actually touch, so the laptop's
            # offset depends on the LG's scale. Pin both scales and derive the
            # coordinates from them, rather than writing numbers that quietly
            # stop lining up the next time a scale changes.
            lg32 = {
              name = "LG Electronics LG HDR 4K 111NTBKD6957";
              resolution = {
                width = 3840;
                height = 2160;
              };
              scale = 1.25;
            };
            framework-13 = {
              name = "BOE NE135A1M-NY1 Unknown";
              resolution = {
                width = 2880;
                height = 1920;
              };
              scale = 2.0;
            };

            logical = output: builtins.mapAttrs (_: px: builtins.floor (px / output.scale)) output.resolution;

            output = display: settings: {
              output = {
                _args = [ display.name ];
                inherit (display) scale;
              }
              // settings;
            };
          in
          [
            # niri has no notion of a primary monitor; focus-at-startup is
            # what decides where the session comes up. Left unset, niri
            # focuses the first output by name, which is the built-in panel.
            (output lg32 {
              focus-at-startup = { };
              position._props = {
                x = 0;
                y = 0;
              };
            })
            # Centred directly underneath the LG, edges touching.
            (output framework-13 {
              position._props = {
                x = ((logical lg32).width - (logical framework-13).width) / 2;
                y = (logical lg32).height;
              };
            })
          ];
      };
    };
}
