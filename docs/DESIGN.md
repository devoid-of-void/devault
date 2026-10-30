# Design and rationale

## Objectives

- Single portable, user-owned encrypted file: no sidecar metadata or special daemon.
- Ordinary-user `create`, `open`, `status` and `close` through UDisks2 and polkit.
- FIDO2 `hmac-secret` with PIN and physical presence, plus a *separate* recovery passphrase.
- Conventional LUKS2 and Btrfs, with compression and sparse initial allocation.
- A documented, completely independent rescue procedure with standard Linux tools.

## Archive format and keying

The backing file is created sparsely, then initialized as LUKS2. Keyslot **0** is the independently chosen recovery passphrase. Keyslot **1** holds the Base64-encoded, FIDO2 HMAC-secret-derived passphrase. LUKS token metadata records the credential ID, salt and relying-party identifier in a `systemd-fido2`-like JSON object. The metadata is not itself the HMAC secret; the enrolled key and PIN/touch must reproduce it.

The metadata and derivation are implemented by devault, not by `systemd-cryptenroll`. Interoperability with native systemd token activation is **not assumed**. The recovery passphrase works with ordinary cryptsetup regardless.

Inside LUKS2 is Btrfs, mounted using `compress=zstd`, with the root inode compression property also set. Compression precedes block encryption. The file's **logical** size is not its initial disk use; consumed space grows and may not shrink on deletion. Do not punch holes in ciphertext to reclaim space.

## Create lifecycle

1. Check path, ownership and dependencies; lock the containing directory using `flock`.
2. Require exactly one accessible FIDO2 device. Create a nonresident credential and per-archive salt.
3. Derive the hmac-secret with PIN/touch, then obtain a separate recovery passphrase.
4. Create the sparse image; initialize LUKS2 and verify recovery keyslot 0.
5. Add and verify keyslot 1 and import token metadata into the LUKS2 header.
6. Attach a loop with UDisks2, unlock via stdin, format the mapped volume as Btrfs via UDisks2.
7. Mount, configure zstd, unmount, lock and release the loop.

Creation refuses overwriting existing files. Interrupted creation can leave an **incomplete** file. Cleanup attempts to undo only operations established by that invocation.

## Open, status and close

`open` identifies an existing loop for that exact file or creates one through UDisks2. It reuses an existing unlocked mapping when found. Otherwise it first tries FIDO2 derivation, submitting the resulting LUKS secret to `udisksctl unlock --key-file /dev/stdin`, or prompts for the recovery passphrase. `--recovery` bypasses FIDO2.

After mounting, devault creates a symlink adjacent to the image (normally `secrets` for `secrets.luks`). It points at the actual UDisks2 mount point, typically under `/run/media/`. `status` discovers devices rather than depending on a state file. `close` unmounts, locks the mapping, removes only its own matching convenience symlink and requests loop removal; loop autoclear is also enabled where possible.

## Authorization and GNOME

UDisks2 offers privileged device operations under polkit policy to an ordinary logged-in user; devault does **not** elevate privileges or bypass policy. `--no-user-interaction` prevents authentication dialogs but may cause operations to fail if policy requires authorization.

GNOME independently monitors attached block devices, potentially causing unwanted automount or authentication prompts. devault temporarily disables `org.gnome.desktop.media-handling automount` under a session-wide `flock` while setting up loops, then restores its previous value. The setting affects the **whole session**. SIGKILL, loss of power or process crashes may leave it changed. See [troubleshooting](TROUBLESHOOTING.md).

## Why this instead of alternatives?

`systemd-cryptenroll` can enroll tokens, but does not solve the ordinary-user loop/mount lifecycle or missing UDisks2 token activation. A custom FUSE encryption scheme would introduce new cryptographic and recovery dependencies. A sidecar keyfile complicates backups. A privileged custom daemon is unnecessary for the normal path.

Ultimately UDisks2 should support token-based LUKS2 unlocking through libblockdev. The current FIDO2-derived-secret bridge is a compatibility solution, not the desired upstream endpoint.

## Boundaries

This is shell orchestration, not a new cryptographic library. Secrets may occupy process memory and pipes; shell tracing/core dumps are disabled, but memory locking and secure wiping are not guaranteed. The code cannot defend against a compromised root account, user session, broken hardware or the absence of backups.
