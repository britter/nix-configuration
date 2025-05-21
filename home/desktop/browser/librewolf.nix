{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.home.desktop.browser.librewolf;
in
{
  options.my.home.desktop.browser.librewolf = {
    enable = lib.mkEnableOption "librewolf";
  };

  config = lib.mkIf cfg.enable {
    programs.librewolf = {
      enable = true;
      settings = {
        "privacy.sanitize.sanitizeOnShutdown" = false;
      };
      # see https://mozilla.github.io/policy-templates/
      policies = {
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DisableFirefoxAccounts = false;
        DisplayBookmarksToolbar = "newtab";
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        OfferToSaveLoginsDefault = false;
        PasswordManagerEnabled = false;
        FirefoxHome = {
          Search = true;
          Pocket = false;
          Snippets = false;
          TopSites = false;
          Highlights = false;
        };
      };
      profiles.bene = {
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          bitwarden
          clearurls
          consent-o-matic
          decentraleyes
          duckduckgo-privacy-essentials
          ghostery
          privacy-badger
          refined-github
          ublock-origin
        ];
        bookmarks = {
          force = true;
          settings = [
            {
              name = "Bookmarks Toolbar";
              toolbar = true;
              bookmarks = [
                {
                  name = "Google Mail";
                  url = "https://mail.google.com";
                }
                {
                  name = "Google Calendar";
                  url = "https://calendar.google.com";
                }
                {
                  name = "Goole Drive";
                  url = "https://drive.google.com";
                }
                {
                  name = "GitHub";
                  url = "https://github.com/notifications";
                }
                {
                  name = "Mastodon";
                  url = "https://chaos.social";
                }
                {
                  name = "Komoot";
                  url = "https://www.komoot.de";
                }
                {
                  name = "Tmux Cheat Sheet";
                  url = "https://tmuxcheatsheet.com";
                }
              ];
            }
          ];
        };
        search = {
          force = true;
          default = "ddg";
          engines = {
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "NixOS Options" = {
              urls = [
                {
                  template = "https://search.nüschtos.de";
                  params = [
                    {
                      name = "scope";
                      value = "NixOS";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };
            "Home Manager Options" = {
              urls = [
                {
                  template = "https://search.nüschtos.de";
                  params = [
                    {
                      name = "scope";
                      value = "Home+Manager";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@hm" ];
            };
            "NixVim" = {
              urls = [
                {
                  template = "https://search.nüschtos.de";
                  params = [
                    {
                      name = "scope";
                      value = "NixVim";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@nv" ];
            };
            "Noogle" = {
              urls = [
                {
                  template = "https://noogle.dev/q";
                  params = [
                    {
                      name = "term";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@ng" ];
            };
            "NixOS Wiki" = {
              urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@nw" ];
            };
            "wikipedia".metaData.alias = "@wiki";
            "google".metaData.hidden = true;
            "amazondotcom-us".metaData.hidden = true;
            "bing".metaData.hidden = true;
            "ebay".metaData.hidden = true;
          };
        };
      };
    };

    xdg = {
      mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = [ "librewolf.desktop" ];
          "application/xhtml+xml" = [ "librewolf.desktop" ];
          "x-scheme-handler/http" = [ "librewolf.desktop" ];
          "x-scheme-handler/https" = [ "librewolf.desktop" ];
          "x-scheme-handler/about" = [ "librewolf.desktop" ];
          "x-scheme-handler/unknown" = [ "librewolf.desktop" ];
        };
      };
    };
  };
}
