{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.system-recovery;
in
{
  options.my.modules.system-recovery = {
    enable = lib.mkEnableOption "system-recovery";
  };

  config = lib.mkIf cfg.enable {
    # Enable Magic SysRq for recovery in emergency situations
    # see https://wiki.nixos.org/wiki/Linux_kernel#Enable_SysRq
    # In short press Alt + SysRq (Print Screen) and then while holding Alt: R E I S U B
    # - R makes the keyboard usable if it's frozen.
    # - E sends a terminate signal to processes, letting them exit cleanly.
    # - I force-kills stubborn processes that ignore E.
    # - S writes all in-memory data to disk, ensuring nothing is lost.
    # - U remounts filesystems as read-only, preventing corruption.
    # - B reboots (or O powers off the machine).
    boot.kernel.sysctl."kernel.sysrq" = 1;
  };
}
