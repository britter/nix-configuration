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
            framework-13 = "BOE NE135A1M-NY1 Unknown";
            lg32 = "LG Electronics LG HDR 4K 111NTBKD6957";
          in
          [
            {
              output = {
                _args = [ lg32 ];
                position = {
                  _props = {
                    x = 0;
                    y = 0;
                  };
                };
              };
            }
            {
              output = {
                _args = [ framework-13 ];
                position = {
                  _props = {
                    x = 480;
                    y = 2160;
                  };
                };
              };
            }
          ];
      };
    };
}
