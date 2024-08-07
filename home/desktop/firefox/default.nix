{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop.firefox;
in {
  options.my.home.desktop.firefox = {
    enable = lib.mkEnableOption "firefox";
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
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
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          clearurls
          consent-o-matic
          decentraleyes
          duckduckgo-privacy-essentials
          ghostery
          onepassword-password-manager
          privacy-badger
          ublock-origin
        ];
        bookmarks = [
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
        search = {
          force = true;
          default = "DuckDuckGo";
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
              definedAliases = ["@np"];
            };
            "Nix Options" = {
              urls = [
                {
                  template = "https://search.nixos.org/options";
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
              definedAliases = ["@no"];
            };
            "NixOS Wiki" = {
              urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = ["@nw"];
            };
            "Wikipedia (en)".metaData.alias = "@wiki";
            "Google".metaData.hidden = true;
            "Amazon.com".metaData.hidden = true;
            "Bing".metaData.hidden = true;
            "eBay".metaData.hidden = true;
          };
        };
      };
    };
  };
}
