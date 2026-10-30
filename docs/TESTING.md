# Testing and verification

Automated smoke checks are **non-destructive** and limited to Bash syntax and command-line behavior. They do not validate cryptography, real FIDO2 hardware, polkit, udisks, GNOME integration or filesystem integrity.

## Static checks (USER)

```sh
bash tests/static.sh
bash -n ./devault
```

On a compatible Linux host, optional additional linting can be done with `shellcheck`. Review security-relevant changes carefully; a passing static check is not an audit.

## Disposable hardware integration test (USER)

Use a new, **disposable** archive, not the only copy of existing data:

```sh
ARCHIVE="$HOME/devault-disposable.luks"
devault create "$ARCHIVE" 1G
devault status "$ARCHIVE"
devault open "$ARCHIVE"
devault status "$ARCHIVE"
```

Note the **printed mount symlink** and create a small test file there. Then close and reopen:

```sh
devault close "$ARCHIVE"
devault open "$ARCHIVE"
devault close "$ARCHIVE"
devault open "$ARCHIVE" --recovery
devault close "$ARCHIVE"
```

Check that the test file persists, that no unexpected mapper/mount/loop remains, and that GNOME's automount setting was restored. Then test [manual recovery](RECOVERY.md) on the **disposable** archive from a root shell. Prove you can unlock without the FIDO2 token or script.

### Failure-path tests

- Missing, reset or wrong FIDO2 key; wrong PIN; fallback to valid recovery passphrase.
- No FIDO2 tooling installed for `open --recovery`.
- Multiple visible FIDO2 keys when creating.
- Abrupt termination and leftover loop or convenience symlink.
- An already mounted image; open/close repetition.
- Busy mount on close (must refuse unsafe detachment).
- Polkit denial with noninteractive authorization requested.
- GNOME automount pre-set to both true and false.
- Btrfs file persistence and compression; sparse image capacity growth.
- Backup, restore, and manual open of an entire image copy.

Any change to FIDO2 derivation, LUKS token JSON, keyslot ordering, input validation, process cleanup or symlink handling requires retesting on real hardware.
