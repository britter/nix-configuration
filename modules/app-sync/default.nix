{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.modules.app-sync;
  syncJob = lib.types.submodule ({config, ...}: {
    options = {
      serviceName = lib.mkOption {
        description = "Name of the service to sync";
        type = lib.types.str;
      };
      host = lib.mkOption {
        description = "Host to sync from";
        type = lib.types.str;
      };
      user = lib.mkOption {
        description = "The user for connecting to the host, defaults to `serviceName`";
        type = lib.types.str;
        default = config.serviceName;
      };
      sshKey = lib.mkOption {
        description = "The SSH used to connect to the host. Defaults to /etc/ssh/ssh_host_ed25519_key";
        type = lib.types.str;
        default = "/etc/ssh/ssh_host_ed25519_key";
      };
      backupDir = lib.mkOption {
        description = "The directory to store temporary files in. Defaults to /var/backups/serviceName`";
        type = lib.types.str;
        default = "/var/backups/${config.serviceName}";
      };
      dataDir = lib.mkOption {
        description = "The data directory to sync.";
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      databaseSync = {
        enable = lib.mkEnableOption "database sync";
        user = lib.mkOption {
          description = "The database user for connecting to the database. Default to `serviceName`.";
          type = lib.types.str;
          default = config.serviceName;
        };
        database = lib.mkOption {
          description = "The database to sync. Defaults to `serviceName`.";
          type = lib.types.str;
          default = config.serviceName;
        };
        dumpFile = lib.mkOption {
          description = "The location of the database dump file. Defaults to `backupDir/serviceName-db.sql`";
          type = lib.types.str;
          default = "${config.backupDir}/${config.serviceName}-db.sql";
        };
      };
      preCommand = lib.mkOption {
        description = "A command to run before running the actual sync.";
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      postCommand = lib.mkOption {
        description = "A command to run after running the actual sync.";
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      runtimeInputs = lib.mkOption {
        description = "Additional runtime inputs required for running the pre or post command";
        type = lib.types.listOf lib.types.package;
        default = [];
      };
    };
  });
  writeSyncScript = job:
    pkgs.writeShellApplication {
      name = "${job.serviceName}-sync";
      runtimeInputs =
        [
          pkgs.openssh
          pkgs.postgresql
          pkgs.rsync
          pkgs.sudo
        ]
        ++ job.runtimeInputs;
      text = lib.strings.concatLines (
        lib.optionals (job.preCommand != null) [job.preCommand]
        ++ ["mkdir -p ${job.backupDir}"]
        ++ lib.optionals job.databaseSync.enable [
          ''ssh -i ${job.sshKey} ${job.user}@${job.host} "pg_dump --username=${job.databaseSync.user} --file=${job.databaseSync.dumpFile} ${job.databaseSync.database}"''
          ''scp -i ${job.sshKey} ${job.user}@${job.host}:${job.databaseSync.dumpFile} ${job.databaseSync.dumpFile}''
          ''ssh -i ${job.sshKey} ${job.user}@${job.host} "rm -f ${job.databaseSync.dumpFile}"''
        ]
        ++ [''rsync -avz --delete --rsh="ssh -i ${job.sshKey}" ${job.user}@${job.host}:${job.dataDir}/ ${job.dataDir}'']
        ++ lib.optionals job.databaseSync.enable [
          ''sudo -u postgres psql --command="DROP DATABASE IF EXISTS ${job.databaseSync.database};"''
          ''sudo -u postgres psql --command="CREATE DATABASE ${job.databaseSync.database} OWNER ${job.databaseSync.user};"''
          ''sudo -u ${job.databaseSync.user} psql --dbname=${job.databaseSync.database} --file=${job.databaseSync.dumpFile}''
          ''rm -f ${job.databaseSync.dumpFile}''
        ]
        ++ ["rm -rf ${job.backupDir}"]
        ++ lib.optionals (job.postCommand != null) [job.postCommand]
      );
    };
in {
  options.my.modules.app-sync = {
    enable = lib.mkEnableOption "app-sync";
    jobs = lib.mkOption {
      type = lib.types.listOf syncJob;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = lib.mkMerge (lib.map (job: {
        services."${job.serviceName}-sync" = {
          description = "Sync job for ${job.serviceName}";
          after = ["network.target"];
          wants = ["network.target"];
          serviceConfig = {
            ExecStart = lib.getExe (writeSyncScript job);
            Type = "oneshot";
          };
        };
        timers."${job.serviceName}-sync" = {
          description = "Timer for ${job.serviceName} sync job";
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
          wantedBy = ["timers.target"];
        };
      })
      cfg.jobs);
  };
}
