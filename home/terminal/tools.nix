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
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        caligula # tui for disk imaging
        curl
        eza # ls replacement
        pdf-fax
        file
        httpie
        jq
        mob # smooth git handover
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
