# Manual recovery without devault

**Keep this document outside the encrypted archive.** These procedures require only an ordinary LUKS2 image, the **independent recovery passphrase**, and stock Linux tools. No FIDO2 key, devault script, UDisks2 or desktop is needed.

**Never run** `luksFormat`, `mkfs.btrfs`, `wipefs`, `luksErase` or any other destructive initialization command on an archive you are recovering.

## Requirements

The complete archive file, your recovery passphrase, Linux with `cryptsetup` and `losetup` and Btrfs filesystem support. This example is for a **ROOT** session, *without sudo*. Replace `/home/username/secrets.luks` with your archive's actual absolute path. Ensure the mapper name `devault-rescue` is not already used.

### 1. Attach the archive (ROOT)

```sh
IMAGE=/home/username/secrets.luks
cryptsetup isLuks --type luks2 "$IMAGE"
LOOP=$(losetup --find --show -- "$IMAGE")
printf 'Loop device: %s\n' "$LOOP"
```

Inspect the actual `/dev/loopN` returned. If the file is already attached, inspect `losetup -j "$IMAGE"` before creating a duplicate attachment.

### 2. Unlock with recovery passphrase (ROOT)

```sh
cryptsetup open --type luks2 --key-slot 0 "$LOOP" devault-rescue
```

Type the independent recovery passphrase when prompted. Keyslot 0 is **not FIDO2-derived**. The decrypted device is now `/dev/mapper/devault-rescue`.

### 3. Mount Btrfs (ROOT)

```sh
mkdir -p /mnt/devault-rescue
mount -t btrfs -o compress=zstd /dev/mapper/devault-rescue /mnt/devault-rescue
ls -la /mnt/devault-rescue
```

Your files are under `/mnt/devault-rescue`. On a different machine, the original numerical file owner IDs may not correspond to your new user. Do not automatically run `chown -R`.

For inspection or copying data from a possibly damaged archive, prefer a read-only mount, *instead of* the read-write mount:

```sh
mount -t btrfs -o ro /dev/mapper/devault-rescue /mnt/devault-rescue
```

### 4. Close the devices cleanly (ROOT)

Close files and leave the mount directory, then:

```sh
umount /mnt/devault-rescue
cryptsetup close devault-rescue
losetup -d "$LOOP"
```

If unmount reports a busy filesystem, stop using it and close any processes holding files open. Do not close a mounted mapper or detach an active loop. Autoclear may already have detached the loop; verify with `losetup -j "$IMAGE"`.

## Non-destructive inspection

These commands read metadata and do **not** erase or initialize the archive:

```sh
cryptsetup luksDump "$IMAGE"
cryptsetup token list "$IMAGE"
```

For a devault v0.9 image, expect a LUKS2 header with recovery keyslot 0, FIDO2 keyslot 1, and FIDO2 token metadata. Exact output depends on cryptsetup version.

## Header backup

LUKS2 header damage can render both unlock methods unusable. After verifying a new disposable archive, consider copying its header to **secure, separate storage** (ROOT or a USER with read permission):

```sh
cryptsetup luksHeaderBackup /path/to/secrets.luks \
  --header-backup-file /secure/backup/location/secrets.luks-header
```

This backup contains keyslot material and permits offline attacks against weak passphrases. Protect it, and take a new backup after changing keyslots. `luksHeaderRestore` can destroy access if applied to the wrong file or with an outdated backup; never use it casually.

## Lost security key or script

The entire point of keyslot 0 is recovery independently of FIDO2. After rescuing the files, make a new archive with a replacement key and copy the contents into it. Do **not** remove the only known-working recovery keyslot.

Although the header records a `systemd-fido2`-like token, this script currently generates that credential itself. Compatibility with systemd-cryptsetup's native token plugin has **not** been independently verified. Do not rely on it as a rescue plan.
