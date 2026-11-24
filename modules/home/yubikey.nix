# YubiKey tooling: key provisioning (ykman), TOTP for OTP-only services
# (Yubico Authenticator), and hardware-backed age identities for the SOPS
# secrets in this repository.
_: {
  flake.modules.homeManager.yubikey =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        yubikey-manager # ykman: FIDO2/PIV/OTP provisioning
        yubioath-flutter # Yubico Authenticator: TOTP for OTP-only services
        sops # edit and re-encrypt encrypted secrets (sops updatekeys)
        age # secret encryption backend for SOPS
        age-plugin-yubikey # PIV-backed age identities for SOPS
      ];
    };

  flake.modules.nixos.yubikey =
    { pkgs, ... }:
    {
      # The PIV application talks to the key over CCID, which needs pcscd.
      services.pcscd.enable = true;

      # udev rules so the keys show up without root.
      services.udev.packages = with pkgs; [
        yubikey-personalization
      ];
    };
}
