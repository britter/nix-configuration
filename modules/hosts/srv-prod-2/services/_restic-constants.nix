{
  bucket-prefix = "s3:https://garage.srv-prod-3.ritter.family/restic-";
  pruneOpts = [
    "--keep-daily 14"
    "--keep-weekly 8"
    "--keep-monthly 12"
    "--keep-yearly 5"
  ];
  timerConfig = {
    OnCalendar = "00:00";
    RandomizedDelaySec = "30m";
    Persistent = true;
  };
}
