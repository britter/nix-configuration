{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./common-utilities
    ./disko
  ];
}
