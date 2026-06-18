{
  bucket = "s3:https://minio.srv-prod-3.ritter.family/restic-backups";
  pruneOpts = [
    "--keep-daily 14"
    "--keep-weekly 8"
    "--keep-monthly 12"
    "--keep-yearly 5"
  ];
  timerConfig = {
    OnCalendar = "00:00";
    RandomizedDelaySec = "30mm";
    Persistent = true;
  };
}
