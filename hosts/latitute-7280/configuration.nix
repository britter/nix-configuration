# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:

{
  imports =
    [ 
      <home-manager/nixos>
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "latitue-7280"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bene = {
    isNormalUser = true;
    description = "Benedikt";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  home-manager.users.bene = { pkgs, ... }: {
    home.stateVersion = "23.05";
    home.packages = [ ];

    programs.firefox.enable = true;
    programs.fish = {
      enable = true;

      shellAliases = {
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        "cat" = "bat";
        "ls" = "exa";
        "ll" = "exa -la";
      };

      shellInit = ''
        set -x LANG en_US.utf-8
        set -x MAVEN_OPTS "-Duser.name=benedikt"
        set PATH /usr/local/bin/usr/local/sbin $JAVA_HOME/bin $HOME/.local/bin $PATH
        set -x EDITOR hx
        set -x GPG_TTY (tty)
        . ~/.asdf/plugins/java/set-java-home.fish
        set -x JDK8 (asdf where java liberica-8u362+9)
        set -x JDK11 (asdf where java liberica-11.0.18+10)
        set -x JDK17 (asdf where java liberica-17.0.6+10)
        set -x JDK18 (asdf where java liberica-18.0.2.1+1)
        starship init fish | source
      '';
    };
    programs.git = {
      enable = true;

      userName = "Benedikt Ritter";
      userEmail = "beneritter@gmail.com";
      signing = {
        signByDefault = true;
        key = "394546A47BB40E12";
      };

      includes = [
        {
          condition = "gitdir:~/github/gradlex-org";
          contents = {
            user.email = "benedikt@gradlex.org";
            user.signingKey = "757DE51A2FD1489D";
          };
        }
        {
          condition = "gitdir:~/github/apache";
          contents = {
            user.email = "britter@apache.org";
            user.signingKey = "9DAADC1C9FCC82D0";
          };
        }
      ];

      aliases = {
        this = "!f() { git init && git add --all && git commit -m 'Initial commit'; }; f";
        tags = "tag -l";
        branches = "branch -a";
        remotes = "remote -v";
        lg = "log --all --graph --pretty=format:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        cleanup = "!f() { git branch --merged main | grep -v main | xargs -n 1 git branch -D;  }; f";
        cleanup-deleted = "!git remote prune origin && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -D";
        sync = "!f() { git checkout main && git fetch upstream && git merge upstream/main && git push origin main && git cleanup && git fetch -p;  }; f";
        merge-back = "!f() { git fetch origin && git checkout release && git merge origin/release && git checkout main && git merge origin/main && git merge release && git cleanup-deleted;  }; f";
        co = "checkout";
        cm = "checkout main";
        st = "status";
        ci = "commit";
        cia = "commit --amend";
        rbi = "rebase --interactive main";
        rbm = "rebase main";
        rbc = "rebase --continue";
      };

      ignores = [
        ## IntelliJ stuff
        ".idea"
        "*.iml"
        "out/"

        ## Mac OS stuff
        ".DS_Store"
      ];

      diff-so-fancy.enable = true;
    };
    programs.gpg.enable = true;
    services.gpg-agent = {
      enable = true;
      pinentryFlavor = "gnome3";
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "1password"
    ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    asdf-vm
    bat # cat replacement
    blackbox-terminal
    exa # ls replacement
    fzf # fuzzy finding
    gh
    gradle
    helix
    jetbrains.idea-community
    pinentry
    starship
    taplo # TOML support in helix
    tldr
    tmux
    xsel # Access to X server clipboard, required for helix clipboard integration
    zip
    zoxide # z for smart directory jumping
  ];

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "Hack" ]; })
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.fish.enable = true;
  programs._1password-gui.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
