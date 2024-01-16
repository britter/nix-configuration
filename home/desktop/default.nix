{pkgs, ...}: {
  imports = [
    ../gnome
    ../firefox
    ../alacritty
    ../vscode
  ];

  # software not available as Home Manager module
  home.packages = with pkgs; [
    jetbrains.idea-community
    fractal-next
  ];
}
