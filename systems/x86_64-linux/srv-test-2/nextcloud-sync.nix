{
  config,
  pkgs,
  ...
}: let
  prodHost = "srv-prod-2";
  nextcloud-sync = let
    nextcloudUser = "nextcloud";
    dataDir = "/var/lib/nextcloud/data";
    dbName = "nextcloud";
    dbDump = "/tmp/nextcloud-prod-dump.sql";
  in
    pkgs.writeShellApplication {
      name = "nextcloud-sync";
      runtimeInputs = [pkgs.rsync config.services.nextcloud.occ];
      text = ''
        nextcloud-occ maintenance:mode --on
        ssh ${prodHost} "pg_dump --username=${nextcloudUser} --file=${dbDump} ${dbName}"
        scp ${prodHost}:${dbDump} ${dbDump}
        ssh ${prodHost} "rm -f ${dbDump}"
        rsync -avz --delete ${prodHost}:${dataDir} ${dataDir}
        sudo -u postgres psql --command="DROP DATABASE IF EXISTS ${dbName};"
        sudo -u postgres psql --command="CREATE DATABASE ${dbName} OWNER ${nextcloudUser};"
        sudo -u ${nextcloudUser} psql --dbname=${dbName} --file=${dbDump}
        rm -f ${dbDump}
        nextcloud-occ maintenance:mode --off
      '';
    };
in {
  environment.systemPackages = [nextcloud-sync];

  programs.ssh.extraConfig = ''
    Host ${prodHost}
      HostName ${config.my.homelab.srv-prod-2.ip}
      User nextcloud
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      IdentitiesOnly yes
  '';
}
