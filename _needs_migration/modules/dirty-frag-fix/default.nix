{
  pkgs,
  ...
}:
{
  boot = {
    # Mitigate the "Dirty Frag" Linux LPE (CVE-2026-43284, CVE-2026-43500).
    # Refuses to load the kernel modules carrying the xfrm-ESP and RxRPC
    # page-cache write primitives until upstream patches land in our pinned
    # kernels. The blacklist entry stops alias-based autoload (e.g. xfrm
    # netlink, AF_RXRPC socket family); the matching `install ... /bin/false`
    # lines in extraModprobeConfig also neutralise explicit `modprobe` and
    # dependency-pulled loads, matching the upstream-recommended fix from
    # https://github.com/V4bel/dirtyfrag and chainguard-dev/infosec's
    # dirtyfrag-fix.sh. Reconsider both blocks if any host ever needs IPsec
    # (esp4/esp6) or AFS/RxRPC (rxrpc/rxkad).
    blacklistedKernelModules = [
      "esp4"
      "esp6"
      "rxrpc"
      "rxkad"
    ];
    extraModprobeConfig = ''
      install esp4 ${pkgs.coreutils}/bin/false
      install esp6 ${pkgs.coreutils}/bin/false
      install rxrpc ${pkgs.coreutils}/bin/false
      install rxkad ${pkgs.coreutils}/bin/false
    '';
  };
}
