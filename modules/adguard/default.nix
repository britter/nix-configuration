{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.modules.adguard;
in {
  options.my.modules.adguard = {
    enable = lib.mkEnableOption "AdGuard";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowedUDPPorts = [config.services.adguardhome.settings.dns.port];
      allowedTCPPorts = [config.services.adguardhome.settings.dns.port];
    };
    services.adguardhome = {
      enable = true;
      # opens a port in the firewall for the web interface
      openFirewall = true;
      # See https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration#configuration-file
      # for possible configuration values
      settings = {
        schema_version = 24;
        dns = {
          port = 53;
          # DDoS protection only required when AdGuard is exposed via the internet
          ratelimit = 0;
          bootstrap_dns = ["1.1.1.1"];
          upstream_dns = [
            # Cloudflare DNS
            "1.1.1.1"
            "https://dns.cloudflare.com/dns-query"
            # Quad 9
            "9.9.9.9"
            "https://dns10.quad9.net/dns-query"
            # Google Public DNS
            "8.8.8.8"
            "https://dns.google/dns-query"
          ];
        };
        filters = [
          # most of this list is shamelessly copied from
          # https://gist.github.com/CRTified/1654c514a74b1049872254394fdc6310
          # Another good source for block lists is https://firebog.net/
          {
            enabled = true;
            id = 1;
            name = "AdGuard DNS filter";
            url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
          }
          {
            enabled = true;
            id = 2;
            name = "AdAway Default Blocklist";
            url = "https://adaway.org/hosts.txt";
          }
          {
            enabled = true;
            id = 1617627869;
            name = "WindowsSpyBlocker - Hosts spy rules";
            url = "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt";
          }
          {
            enabled = true;
            id = 1617627870;
            name = "Peter Lowe's List";
            url = "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=1&mimetype=plaintext";
          }
          {
            enabled = true;
            id = 1617627871;
            name = "Game Console Adblock List";
            url = "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/GameConsoleAdblockList.txt";
          }
          {
            enabled = true;
            id = 1617627872;
            name = "Spam404";
            url = "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt";
          }
          {
            enabled = true;
            id = 1617627873;
            name = "NoCoin Filter List";
            url = "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt";
          }
          {
            enabled = true;
            id = 1617627874;
            name = "Dan Pollock's List";
            url = "https://someonewhocares.org/hosts/zero/hosts";
          }
          {
            enabled = true;
            id = 1617627875;
            name = "Perflyst and Dandelion Sprout's Smart-TV Blocklist";
            url = "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV-AGH.txt";
          }
          {
            enabled = true;
            id = 1617627876;
            name = "The Big List of Hacked Malware Web Sites";
            url = "https://raw.githubusercontent.com/mitchellkrogza/The-Big-List-of-Hacked-Malware-Web-Sites/master/hosts";
          }
          {
            enabled = true;
            id = 1617627877;
            name = "Online Malicious URL Blocklist";
            url = "https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-agh-online.txt";
          }
          {
            enabled = true;
            id = 1617627878;
            name = "oisd full";
            url = "https://abp.oisd.nl/";
          }
        ];
        filtering = {
          # make 192.168.178.105 (this host) available via domain home.arpa
          # home.arpa is a special purpose domain for local networks,
          # see https://datatracker.ietf.org/doc/html/rfc8375
          #
          # For this to work is requires assigning 192.168.178.105 as a static
          # IP in to this host in the router configuration.
          filtering_enabled = true;
          rewrites = [
            {
              domain = "home.arpa";
              answer = "192.168.178.105";
            }
            {
              domain = "*.home.arpa";
              answer = "192.168.178.105";
            }
          ];
        };
      };
    };
  };
}
