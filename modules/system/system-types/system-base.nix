{ inputs, ... }:
{
  flake.modules.nixos.system-base =
    { pkgs, ... }:
    {
      imports = [ inputs.self.modules.nixos.i18n ];

      environment.systemPackages = with pkgs; [
        curl
        dig
        git
        lsof
        neovim
        nix-tree
        nix-output-monitor
        nh
        unzip
        tmux
        wget
        zip
      ];
    };
}
