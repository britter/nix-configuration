{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.home.terminal.tools;
in
{
  options.my.home.terminal.tools = {
    enable = lib.mkEnableOption "tools";
  };
  config =
    let
      pdf-fax = pkgs.writeShellApplication {
        name = "pdf-fax";
        runtimeInputs = [ pkgs.ghostscript_headless ];
        text = ''
          rotation=$((1 + RANDOM % 1000))
          bool=$((1 + RANDOM % 2))
          if [ $bool -eq 1 ]; then
            sign="-"
          else
            sign="+"
          fi
          ${pkgs.imagemagick}/bin/magick -density 150 "$1" -rotate "''${sign}0.$rotation" -attenuate 0.4 +noise Multiplicative -attenuate 0.03 +noise Multiplicative -sharpen 0x1.0 -colorspace Gray "$2"
        '';
      };
      captive-portal = pkgs.writeShellApplication {
        name = "captive-portal";
        runtimeInputs = [ pkgs.networkmanager ];
        text = ''
          PORTAL_URL=http://"$(ip -oneline route get 1.1.1.1 | awk '{print $3}')"
          if nmcli -t -f name connection show --active | grep -qx "WIFIonICE"; then
              PORTAL_URL="https://login.wifionice.de"
          fi

          xdg-open "$PORTAL_URL"
        '';
      };
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        caligula # tui for disk imaging
        captive-portal
        curl
        eza # ls replacement
        fd # find replacement
        file
        httpie
        jq
        mob # smooth git handover
        pdf-fax
        tokei # count lines of code
        tealdeer # better man pages
        unzip
        wget
        yq-go
        zip
      ];
      programs.ripgrep.enable = true; # recursive grep
      programs.zoxide.enable = true; # smart cd replacement
    };
}
