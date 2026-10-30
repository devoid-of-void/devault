# Troubleshooting

## Key absent, wrong PIN, or multiple keys

Creation expects **exactly one accessible** FIDO2 device with `hmac-secret` support. Check as **USER**:

```sh
fido2-token -L
```

If the key is absent, reset or inaccessible, use the independent recovery path:

```sh
devault open /path/to/secrets.luks --recovery
```

Never remove recovery keyslot 0 without verifying another independent way in.

## GNOME popup or automount race

GNOME monitors new block devices; it can race loop setup and ask for authentication. devault temporarily disables the user's automount setting under an advisory lock and restores the prior value. UDisks2 commands use `--no-user-interaction` to prevent polkit dialogs, not to grant permission.

Check the setting (**USER**):

```sh
gsettings get org.gnome.desktop.media-handling automount
```

If the script was killed and you normally used automatic mounting, restore it (**USER**):

```sh
gsettings set org.gnome.desktop.media-handling automount true
```

Use your **previous** setting if it was not `true`. The coordination lock is ordinarily `$XDG_RUNTIME_DIR/devault-automount.lock`; do not remove it while another devault process is running.

## Polkit denies loop, unlock, format or mount

UDisks2 must authorize ordinary-user operations for the current local session. `--no-user-interaction` fails instead of opening an authentication popup when a policy challenge would be needed. Confirm the session, UDisks2 daemon, filesystem permissions, and local polkit policy. Do not make the whole script setuid or run it as root.

Manual emergency access via the recovery passphrase is documented in [RECOVERY.md](RECOVERY.md) and intentionally uses a root shell with stock tools.

## Loop remains after close

Inspect (ROOT or authorized USER where applicable):

```sh
losetup -j /path/to/secrets.luks
lsblk -o NAME,TYPE,FSTYPE,MOUNTPOINTS,BACK-FILE
```

Ensure no mounted filesystem or unlocked mapper depends on the loop. If UDisks2 cannot remove a verified, unused loop, detach the **correct device** from a ROOT shell:

```sh
losetup -d /dev/loopN
```

`/dev/loopN` is only a placeholder; never detach another archive's device. The kernel can automatically detach autoclear loops after the last reference disappears.

## Symlink absent or stale

For `/path/secrets.luks`, a successful open normally creates `/path/secrets` pointing at the actual UDisks2 mount. If another file, directory or unrelated link already occupies that name, devault leaves it unchanged.

A forced kill may leave a stale convenience symlink. Verify with `readlink` and `findmnt`. Remove it manually only after ensuring it is yours and points nowhere needed.

## Busy filesystem

Close shells located inside the mount, file managers, editors, and processes with open files. Inspect with `findmnt` and retry `devault close`. Do not forcibly tear down an in-use mapping.

## Incorrect passphrase or intermittent cryptsetup failure

Verify keyslot metadata non-destructively using `cryptsetup luksDump`, test on a complete backup copy, and verify RAM/storage stability. Unstable memory can cause sporadic authentication failures and potentially corrupt data. Avoid repeated keyslot changes on questionable hardware.

## Lost script, GNOME or key

The archive is ordinary LUKS2 and Btrfs. Use the **independent recovery passphrase** and the exact instructions in [RECOVERY.md](RECOVERY.md).
