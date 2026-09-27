# Desktop manual setup

Stateful changes made by hand on framework-13 that the flake cannot express.
Needed again when reinstalling from scratch.

## gnome-keyring under autologin

`greetd.settings.initial_session` logs `bene` in without a password. The
keyring passphrase is the login password, and `pam_gnome_keyring` unlocks the
keyring with whatever gets typed at login. Under autologin nothing is typed, so
the first secret request (nextcloud-client, git-credential-libsecret) pops a
password prompt. That brings back a second password after the LUKS one, which
is what autologin was supposed to get rid of.

Both keyrings were given an empty password via `nix run nixpkgs#seahorse`,
right-click the keyring, *Change Password*, enter the current password, leave
the new one blank, confirm the warning about storing unencrypted.

Login (`~/.local/share/keyrings/login.keyring`) holds a single item,
`Unlock password for: Default keyring`. Default holds the actual secrets,
including the nextcloud-client password. Blanking Login alone did not help:
Default still prompted, so that auto-unlock item is apparently never consulted.
Blanking Default is what removed the prompt.

The secrets now sit unencrypted in `~/.local/share/keyrings/`, mode 0600,
protected by LUKS and file permissions only. Under autologin that gives up
nothing real, since anyone who can unlock LUKS lands in the session anyway.

To revert, set a password on each keyring the same way in seahorse and drop
`greetd.settings.initial_session` so greetd asks for the login password again.
Both steps are needed, because a keyring password without a login prompt just
recreates the problem.

### greetd and PAM

`services.gnome.gnome-keyring.enable` only sets
`security.pam.services.login.enableGnomeKeyring`, and greetd does not use the
`login` PAM service. So this configuration has no gnome-keyring PAM module in
the session at all and the daemon gets started by D-Bus activation on the first
secret request. That may well be why the auto-unlock item in the login keyring
does nothing.

If autologin is ever turned off, set
`security.pam.services.greetd.enableGnomeKeyring = true`. Without it, keyring
unlocking will not work even with a real login prompt.
