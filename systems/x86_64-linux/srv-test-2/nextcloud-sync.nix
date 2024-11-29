{
  config,
  pkgs,
  ...
}: let
  nextcloud-sync = let
    prodHost = config.my.homelab.srv-prod-2.ip;
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
        ssh ${nextcloudUser}@${prodHost} "pg_dump --username=${nextcloudUser} --file=${dbDump} ${dbName}"
        scp ${nextcloudUser}@${prodHost}:${dbDump} ${dbDump}
        ssh ${nextcloudUser}@${prodHost} "rm -f ${dbDump}"
        rsync -avz --delete ${nextcloudUser}@${prodHost}:${dataDir} ${dataDir}
        sudo -u postgres psql --command="DROP DATABASE IF EXISTS ${dbName};"
        sudo -u postgres psql --command="CREATE DATABASE ${dbName} OWNER ${nextcloudUser};"
        sudo -u ${nextcloudUser} psql --dbname=${dbName} --file=${dbDump}
        rm -f ${dbDump}
        nextcloud-occ maintenance:mode --off
      '';
    };
in {
  environment.systemPackages = [nextcloud-sync];
}
