# Security model and limitations

This project orchestrates standard cryptographic components; it does not implement its own encryption cipher. Treat v0.9 as **experimental security-sensitive shell code**, not an audited product. Verify both unlock methods and manual recovery before placing valuable data in an archive.

## Intended protection

An attacker who obtains only a **closed** LUKS2 archive should need the recovery passphrase or the FIDO2-derived unlock secret to decrypt it. LUKS2 implements the encryption; devault coordinates FIDO2 `hmac-secret`, cryptsetup and UDisks2.

Both LUKS2 keyslots are independent access routes. A strong hardware key does **not** compensate for a weak recovery passphrase: someone with a copy of the archive can attack keyslot 0 offline, subject to the LUKS key-derivation cost. Use a long, high-entropy recovery passphrase and keep it separate from the archive.

## Not protected

- **Open/mounted archives:** programs with permission to access mounted files can read plaintext.
- **Compromised root or user session:** malware can inspect files, intercept PIN/password entry and capture transient secrets.
- **RAM and swap:** Bash variables and pipes contain sensitive material. The script disables tracing and core dumps, but cannot lock memory or guarantee that transient secrets were overwritten. Use encrypted swap where appropriate.
- **Host copies:** editors, caches, thumbnails, indexers, swap, backups and crash reports may expose plaintext outside the archive.
- **Active tampering:** ordinary LUKS2 encryption here does not provide per-sector authenticated encryption. Btrfs checksums help detect corruption, not reliably authenticate data against an adversary who can rewrite ciphertext.
- **Availability:** hardware loss, unrecoverable header corruption, defective RAM/storage, deletion or forgotten recovery passphrases can still destroy access.

## FIDO2 and token metadata

Creation requires exactly one accessible FIDO2 key providing `hmac-secret` and the expected PIN/user-presence behavior. The credential is nonresident; the LUKS2 header stores its identifier, salt and related **nonsecret** token fields. Resetting or replacing the device breaks that FIDO2 unlock path. Keyslot 0 should remain independent.

The script labels its metadata `systemd-fido2` but derives the credential itself; interoperability with systemd's native token plugin has **not been verified**. Do not remove recovery keyslot 0 on the assumption another program can unlock the archive.

## Storage and backups

- Maintain multiple independent backups of irreplaceable archives and test restoring them.
- Keep a separate, offline copy of the recovery passphrase. It is the guaranteed way to recover without devault or the token.
- Consider a **separate secure LUKS header backup**, refreshed after enrollment or keyslot changes. A stolen header backup enables offline passphrase attempts; treat it as sensitive.
- Watch the host filesystem's free space. A sparse 8G image can eventually occupy 8G plus overhead. Do not punch holes in the encrypted file to reclaim space.
- Avoid committing real archives, header backups or secrets to Git. `.gitignore` is only an accident-prevention measure.
- Validate RAM/storage reliability. Random passphrase failures may result from memory corruption, not the key.

## Permissions and operational behavior

The script requires user-owned regular archive files, refuses symlink inputs and uses directory-wide advisory locks to coordinate its own operations. It calls UDisks2 via authorization policy, not privilege escalation. The `--no-user-interaction` option suppresses polkit dialogs but does not bypass denied authorization.

GNOME's global automount setting may be changed temporarily and can remain changed after abnormal termination. See [troubleshooting](TROUBLESHOOTING.md).

## Reporting security problems

Use disposable test images, never real credentials or sensitive archive contents, in public bug reports. GitHub private vulnerability reporting should be enabled by the repository owner where available.
