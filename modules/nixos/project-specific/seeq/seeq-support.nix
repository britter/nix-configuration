_: {
  # nix-ld provides an FHS-style loader so unpatched dynamic binaries can run.
  flake.modules.nixos.seeq-support = { config, pkgs, ... }: {
    # required to run Seeq's toolchain management
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # required by Python
        sqlite
        libffi # ctypes
        gdbm # dbm.gnu
        ncurses # curses
        readline

        # required by the nginx shipped in Seeq's image (libcrypt.so.1)
        libxcrypt-legacy

        # required by the JDK's AWT libraries
        libxtst

        # required by Playwright
        libxcb
        libx11
        libxext
        libxrandr
        libxcomposite
        libxcursor
        libxdamage
        libxfixes
        libxi
        libxrender
        gtk3
        pango
        atk
        cairo
        gdk-pixbuf
        glib
        alsa-lib
        freetype
        fontconfig
        dbus
        nss
        nspr
        expat
        libdrm
        libgbm
        libxkbcommon
        at-spi2-atk
        at-spi2-core
        cups
      ];
    };
    # allows running bash scripts with #!/bin/bash shebang
    services.envfs = {
      enable = true;
      extraFallbackPathCommands = ''
        ln -s ${pkgs.bash}/bin/bash $out/bash
        # Seeq's docker toolchain script looks docker up with a hard-coded FHS PATH
        ln -s ${config.virtualisation.docker.package}/bin/docker $out/docker
      '';
    };

    # Seeq services listen in ports below 34410; keep the kernel's ephemeral ports out of that
    # range.
    boot.kernel.sysctl."net.ipv4.ip_local_port_range" = "34410 60999";

    virtualisation.docker.enable = true;
    users.users.bene.extraGroups = [ "docker" ];
    # Seeq's docker toolchain script writes this via sudo if it's missing or lacks buildkit
    environment.etc."docker/daemon.json".text = builtins.toJSON { features.buildkit = true; };

    # sq-alter-ps1.sh (sourced by crab's `environment`) calls __git_ps1, but only looks for
    # git-prompt.sh in FHS locations.
    programs.git = {
      enable = true;
      prompt.enable = true;
    };

    home-manager.sharedModules = [
      ({ config, lib, ... }: {
        home.packages = [ pkgs.azure-cli ];
        # Seeq's claude-code toolchain package only checks ~/.local/bin/claude and writes
        # autoUpdatesChannel into settings.json if it's missing. Point it at the Nix-managed
        # claude and pre-set the key; the Nix wrapper sets DISABLE_AUTOUPDATER=1, so it's a no-op.
        programs.claude-code.settings.autoUpdatesChannel = "stable";
        home.file.".local/bin/claude".source = lib.getExe config.programs.claude-code.finalPackage;

        programs.nono.profiles."seeq" = {
          extends = [ "claude" ];
          meta = {
            version = "1.0.0";
            description = "Additions for working on seeq projects";
          };
          filesystem.allow = [
            "~/sq"
            "~/github/seeq12"
            "~/.cache/ms-playwright"
          ];
        };
      })
    ];
  };
}
