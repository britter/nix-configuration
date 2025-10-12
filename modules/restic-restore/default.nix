{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  # Type for a valid systemd unit option. Needed for correctly passing "timerConfig" to "systemd.timers"
  inherit (utils.systemdUtils.unitOptions) unitOption;
in
{
  options.services.restic.restores = lib.mkOption {
    description = ''
      Periodic restores from Restic.
    '';
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            passwordFile = lib.mkOption {
              type = lib.types.str;
              description = ''
                Read the repository password from a file.
              '';
              example = "/etc/nixos/restic-password";
            };

            environmentFile = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = ''
                file containing the credentials to access the repository, in the
                format of an EnvironmentFile as described by {manpage}`systemd.exec(5)`
              '';
            };

            repository = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = ''
                repository to restore from.
              '';
              example = "sftp:restore@192.168.1.100:/backups/${name}";
            };

            repositoryFile = lib.mkOption {
              type = with lib.types; nullOr path;
              default = null;
              description = ''
                Path to the file containing the repository location to restore to.
              '';
            };

            paths = lib.mkOption {
              # This is nullable for legacy reasons only. We should consider making it a pure listOf
              # after some time has passed since this comment was added.
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = ''
                Which paths to restore.
              '';
              example = [
                "/var/lib/postgresql"
                "/home/user/backup"
              ];
            };

            timerConfig = lib.mkOption {
              type = lib.types.nullOr (lib.types.attrsOf unitOption);
              default = {
                OnCalendar = "daily";
                Persistent = true;
              };
              description = ''
                When to run the restore. See {manpage}`systemd.timer(5)` for
                details. If null no timer is created and the restore will only
                run when explicitly started.
              '';
              example = {
                OnCalendar = "00:05";
                RandomizedDelaySec = "5h";
                Persistent = true;
              };
            };

            user = lib.mkOption {
              type = lib.types.str;
              default = "root";
              description = ''
                As which user the restore should run.
              '';
              example = "postgresql";
            };

            restorePrepareCommand = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = ''
                A script that must run before starting the restore process.
              '';
            };

            restorePostCommand = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = ''
                A script that must run after finishing the restore process.
              '';
            };

            package = lib.mkPackageOption pkgs "restic" { };

            createWrapper = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Whether to generate and add a script to the system path, that has the same environment variables set
                as the systemd service. This can be used to e.g. mount snapshots or perform other opterations, without
                having to manually specify most options.
              '';
            };
          };
        }
      )
    );
    default = { };
  };

  config = {
    systemd.services = lib.mapAttrs' (
      name: restore:
      let
        resticCmd = "${lib.getExe restore.package}";
        doRestore = restore.paths != [ ];
      in
      lib.nameValuePair "restic-restores-${name}" (
        {
          environment = {
            # not %C, because that wouldn't work in the wrapper script
            RESTIC_CACHE_DIR = "/var/cache/restic-restores-${name}";
            RESTIC_REPOSITORY = restore.repository;
          };
          restartIfChanged = false;
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart =
              let
                includes = lib.map (p: "--include ${p}") restore.paths;
              in
              lib.optionals doRestore [
                "${resticCmd} restore latest --no-lock ${lib.concatStringsSep " " includes} --delete --target /"
              ];
            User = restore.user;
            RuntimeDirectory = "restic-restores-${name}";
            CacheDirectory = "restic-restores-${name}";
            CacheDirectoryMode = "0700";
            PrivateTmp = true;
          }
          // lib.optionalAttrs (restore.environmentFile != null) {
            EnvironmentFile = restore.environmentFile;
          };
        }
        // lib.optionalAttrs (doRestore && restore.restorePrepareCommand != null) {
          preStart = "${pkgs.writeScript "restorePrepareCommand" restore.restorePrepareCommand}";
        }
        // lib.optionalAttrs (doRestore && restore.restorePostCommand != null) {
          postStop = "${pkgs.writeScript "restorePostCommand" restore.restorePostCommand}";
        }
      )
    ) config.services.restic.restores;
    systemd.timers = lib.mapAttrs' (
      name: restore:
      lib.nameValuePair "restic-restores-${name}" {
        wantedBy = [ "timers.target" ];
        inherit (restore) timerConfig;
      }
    ) (lib.filterAttrs (_: restore: restore.timerConfig != null) config.services.restic.restores);

    # generate wrapper scripts, as described in the createWrapper option
    environment.systemPackages = lib.mapAttrsToList (
      name: restore:
      let
        resticCmd = "${lib.getExe restore.package}";
      in
      pkgs.writeShellScriptBin "restic-${name}" ''
          set -a  # automatically export variables
        ${lib.optionalString (restore.environmentFile != null) "source ${restore.environmentFile}"}
        # set same environment variables as the systemd service
            ${lib.pipe config.systemd.services."restic-restores-${name}".environment [
              (lib.filterAttrs (n: v: v != null && n != "PATH"))
              (lib.mapAttrs (_: v: "${v}"))
              lib.toShellVars
            ]}
        PATH=${config.systemd.services."restic-restores-${name}".environment.PATH}:$PATH

        exec ${resticCmd} "$@"
      ''
    ) (lib.filterAttrs (_: v: v.createWrapper) config.services.restic.restores);
  };
}
