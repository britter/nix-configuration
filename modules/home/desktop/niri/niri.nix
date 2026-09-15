{ config, ... }:
let
  outer = config;
in
{
  flake.modules.nixos.niri =
    { ... }:
    {
      imports = with outer.flake.modules.nixos; [
        noctalia
      ];

      # puts systemd init logs on tty1
      # so that tuigreet and systemd logs don't clobber each other
      boot.kernelParams = [ "console=tty1" ];

      # Registers the session with the display manager and wires up the
      # portals, polkit agent and keyring integration niri expects. The
      # gnome portal is what provides the screencast source picker.
      programs.niri.enable = true;

      services = {
        displayManager = {
          autoLogin = {
            enable = true;
            user = "bene";
          };
          sddm = {
            enable = true;
            wayland.enable = true;
          };
        };

        # Required for automatically mounting USB devices
        devmon.enable = true;
        gvfs.enable = true;
        udisks2.enable = true;
      };
    };

  flake.modules.homeManager.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      ns = lib.getExe config.programs.noctalia.package;
      niri = lib.getExe config.wayland.windowManager.niri.package;

      palette =
        (lib.importJSON "${config.catppuccin.sources.palette}/palette.json")
        .${config.catppuccin.flavor}.colors;
      color = name: palette.${name}.hex;

      # A niri bind is a KDL node whose only child is the action. Actions
      # without arguments are written as empty nodes.
      act = name: { ${name} = { }; };
      spawn = args: { spawn = args; };
      nsmsg =
        args:
        spawn (
          [
            ns
            "msg"
          ]
          ++ args
        );

      # Upstream binds the vim keys and the arrow keys to the same four
      # directional actions, so generate both halves from one table.
      directions =
        prefix:
        {
          left,
          down,
          up,
          right,
        }:
        {
          "${prefix}H" = act left;
          "${prefix}Left" = act left;
          "${prefix}J" = act down;
          "${prefix}Down" = act down;
          "${prefix}K" = act up;
          "${prefix}Up" = act up;
          "${prefix}L" = act right;
          "${prefix}Right" = act right;
        };

      # Several actions are reachable through more than one key.
      alias = keys: name: lib.genAttrs keys (_: act name);
      aliasBind = keys: bind: lib.genAttrs keys (_: bind);

      windowRule = children: { window-rule._children = children; };
    in
    {
      imports = with outer.flake.modules.homeManager; [
        noctalia
        desktop-apps
      ];

      home.packages = with pkgs; [
        wl-clipboard
        wl-mirror
      ];

      wayland.windowManager.niri = {
        enable = true;

        # The NixOS module already installs and configures the portals;
        # letting home-manager install a second copy only duplicates them.
        portalPackage = null;

        settings = {
          # Ask applications to drop their own decorations so niri can draw
          # focus rings around windows rather than through them.
          prefer-no-csd = { };

          # Match the directory and naming noctalia uses, so all three
          # screenshot binds deposit their output in the same place.
          screenshot-path = "~/Pictures/screenshot_%Y%m%d_%H%M%S.png";

          input = {
            keyboard.xkb.options = "compose:caps";
            touchpad = {
              tap = { };
              natural-scroll = { };
            };
          };

          layout = {
            # Applied around every window, so adjacent columns end up twice
            # this far apart. niri has no column-only gap setting.
            gaps = 4;

            focus-ring = {
              width = 2;
              active-color = color config.catppuccin.accent;
              inactive-color = color "overlay0";
              urgent-color = color "peach";
            };
          };

          binds =
            # Focus, move, and the monitor-level equivalents of both. Bare
            # Mod focuses, Ctrl moves the thing, Shift raises the scope.
            directions "Mod+" {
              left = "focus-column-left";
              down = "focus-window-down";
              up = "focus-window-up";
              right = "focus-column-right";
            }
            // directions "Mod+Ctrl+" {
              left = "move-column-left";
              down = "move-window-down";
              up = "move-window-up";
              right = "move-column-right";
            }
            // directions "Mod+Shift+" {
              left = "focus-monitor-left";
              down = "focus-monitor-down";
              up = "focus-monitor-up";
              right = "focus-monitor-right";
            }
            // directions "Mod+Shift+Ctrl+" {
              left = "move-column-to-monitor-left";
              down = "move-column-to-monitor-down";
              up = "move-column-to-monitor-up";
              right = "move-column-to-monitor-right";
            }

            # Mod+T is niri's own binding and the one the hotkey overlay and
            # upstream documentation advertise; Mod+Return is the sway habit.
            // aliasBind [ "Mod+T" "Mod+Return" ] {
              _props.hotkey-overlay-title = "Open a Terminal";
              spawn = [ (lib.getExe pkgs.ghostty) ];
            }

            # Workspaces are a dynamic per-monitor stack, so they are
            # navigated by direction rather than addressed by number.
            // alias [ "Mod+Page_Down" "Mod+U" ] "focus-workspace-down"
            // alias [ "Mod+Page_Up" "Mod+I" ] "focus-workspace-up"
            // alias [ "Mod+Ctrl+Page_Down" "Mod+Ctrl+U" ] "move-column-to-workspace-down"
            // alias [ "Mod+Ctrl+Page_Up" "Mod+Ctrl+I" ] "move-column-to-workspace-up"
            // alias [ "Mod+Shift+Page_Down" "Mod+Shift+U" ] "move-workspace-down"
            // alias [ "Mod+Shift+Page_Up" "Mod+Shift+I" ] "move-workspace-up"

            // {
              # Applications and shell surfaces.
              "Mod+D" =
                nsmsg [
                  "panel-toggle"
                  "launcher"
                ]
                // {
                  _props.hotkey-overlay-title = "Run an Application";
                };
              "Mod+Escape" =
                nsmsg [
                  "panel-toggle"
                  "session"
                ]
                // {
                  _props.hotkey-overlay-title = "Session Menu";
                };
              "Mod+Shift+Slash" = act "show-hotkey-overlay";

              # Screenshots stay on noctalia for its annotation editor and
              # adjustable region selection; niri contributes the window
              # picker, which noctalia has no equivalent for. This keyboard
              # has no Print key, so they hang off Mod rather than niri's
              # default Print bindings.
              "Mod+X" = nsmsg [ "screenshot-region" ];
              "Mod+Shift+X" = nsmsg [
                "screenshot-fullscreen"
                "pick"
              ];
              "Mod+Ctrl+X" = act "screenshot-window";

              # Mirror the focused output into a window, which is then moved
              # onto the projector and fullscreened with Mod+Shift+F.
              "Mod+P" = {
                _props = {
                  repeat = false;
                  hotkey-overlay-title = "Mirror the Focused Output";
                };
                spawn-sh = "${lib.getExe pkgs.wl-mirror} $(${niri} msg --json focused-output | ${lib.getExe pkgs.jq} -r .name)";
              };

              # Swap what a running screencast shows without renegotiating
              # the share in the conferencing application.
              "Mod+Shift+C" = act "set-dynamic-cast-window";
              "Mod+Ctrl+Shift+C" = act "set-dynamic-cast-monitor";
              "Mod+Ctrl+Shift+X" = act "clear-dynamic-cast-target";

              "Mod+O" = {
                _props.repeat = false;
                toggle-overview = { };
              };
              "Mod+Q" = {
                _props.repeat = false;
                close-window = { };
              };
              "Mod+Shift+E" = act "quit";
              "Mod+Shift+P" = act "power-off-monitors";

              # Columns: build one by pulling neighbours in, break it apart
              # by pushing them back out.
              "Mod+BracketLeft" = act "consume-or-expel-window-left";
              "Mod+BracketRight" = act "consume-or-expel-window-right";
              "Mod+Comma" = act "consume-window-into-column";
              "Mod+Period" = act "expel-window-from-column";
              "Mod+W" = act "toggle-column-tabbed-display";
              "Mod+Home" = act "focus-column-first";
              "Mod+End" = act "focus-column-last";
              "Mod+Ctrl+Home" = act "move-column-to-first";
              "Mod+Ctrl+End" = act "move-column-to-last";

              # Column and window sizing.
              "Mod+R" = act "switch-preset-column-width";
              "Mod+Shift+R" = act "switch-preset-column-width-back";
              "Mod+Ctrl+R" = act "reset-window-height";
              "Mod+Ctrl+Shift+R" = act "switch-preset-window-height";
              "Mod+Minus".set-column-width = "-10%";
              "Mod+Equal".set-column-width = "+10%";
              "Mod+Shift+Minus".set-window-height = "-10%";
              "Mod+Shift+Equal".set-window-height = "+10%";
              "Mod+C" = act "center-column";
              "Mod+Ctrl+C" = act "center-visible-columns";
              "Mod+Ctrl+F" = act "expand-column-to-available-width";

              "Mod+F" = act "maximize-column";
              "Mod+M" = act "maximize-window-to-edges";
              "Mod+Shift+F" = act "fullscreen-window";
              # Tells an application it went fullscreen while leaving it a
              # normal window, for sharing browser slide decks.
              "Mod+Ctrl+Shift+F" = act "toggle-windowed-fullscreen";

              "Mod+V" = act "toggle-window-floating";
              "Mod+Shift+V" = act "switch-focus-between-floating-and-tiling";

              # Scrolling the strip and the workspace stack.
              "Mod+WheelScrollDown" = {
                _props.cooldown-ms = 150;
                focus-workspace-down = { };
              };
              "Mod+WheelScrollUp" = {
                _props.cooldown-ms = 150;
                focus-workspace-up = { };
              };
              "Mod+Ctrl+WheelScrollDown" = {
                _props.cooldown-ms = 150;
                move-column-to-workspace-down = { };
              };
              "Mod+Ctrl+WheelScrollUp" = {
                _props.cooldown-ms = 150;
                move-column-to-workspace-up = { };
              };
              "Mod+WheelScrollRight" = act "focus-column-right";
              "Mod+WheelScrollLeft" = act "focus-column-left";
              "Mod+Ctrl+WheelScrollRight" = act "move-column-right";
              "Mod+Ctrl+WheelScrollLeft" = act "move-column-left";
              "Mod+Shift+WheelScrollDown" = act "focus-column-right";
              "Mod+Shift+WheelScrollUp" = act "focus-column-left";
              "Mod+Ctrl+Shift+WheelScrollDown" = act "move-column-right";
              "Mod+Ctrl+Shift+WheelScrollUp" = act "move-column-left";
            }

            # Fn row. These stay live while the session is locked.
            // lib.mapAttrs (_: v: v // { _props.allow-when-locked = true; }) {
              "XF86AudioMute" = nsmsg [ "volume-mute" ];
              "XF86AudioRaiseVolume" = nsmsg [ "volume-up" ];
              "XF86AudioLowerVolume" = nsmsg [ "volume-down" ];
              "XF86MonBrightnessUp" = nsmsg [ "brightness-up" ];
              "XF86MonBrightnessDown" = nsmsg [ "brightness-down" ];
            };

          _children = [
            # Matchless, so it applies to every window. The radius alone only
            # rounds the focus ring; clipping is what rounds the window
            # itself, and it also cuts off client-side shadows. 12 matches
            # noctalia's default panel radius.
            (windowRule [
              { geometry-corner-radius = 12; }
              { clip-to-geometry = true; }
            ])

            # Anything launched with an app id ending in "-floating" opens
            # as a floating window.
            (windowRule [
              { match._props.app-id = "-floating$"; }
              { open-floating = true; }
            ])

            (windowRule [
              { match._props.app-id = "^qalculate-gtk$"; }
              { open-floating = true; }
              { default-column-width.fixed = 800; }
              { default-window-height.fixed = 600; }
            ])

            # Floating, and blacked out in screencasts so a shared screen
            # never leaks the vault.
            (windowRule [
              { match._props.app-id = "^Bitwarden$"; }
              { open-floating = true; }
              { block-out-from = "screencast"; }
            ])

            # Makes it obvious at a glance which window a call is showing.
            (windowRule [
              { match._props.is-window-cast-target = true; }
              {
                focus-ring = {
                  active-color = color "yellow";
                  inactive-color = color "yellow";
                };
              }
            ])
          ];
        };
      };
    };
}
