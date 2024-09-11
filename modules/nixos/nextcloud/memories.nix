{
  config,
  pkgs,
  ...
}: {
  services.nextcloud = {
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) memories;
    };
  };

  environment.systemPackages = with pkgs; [
    ffmpeg
  ];
}
