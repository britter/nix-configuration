{pkgs, ...}:
with pkgs; {
  fritzbox-cloudflare-dyndns = callPackage ./fritzbox-cloudflare-dyndns {};
  gh-get = callPackage ./gh-get {};
  groovy-language-server = callPackage ./groovy-language-server {};
}
