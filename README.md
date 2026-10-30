# devault

**Rootless FIDO2-protected encrypted archives for Linux.** One file, ordinary-user commands, and a recovery passphrase that works even after the script or security key is gone.

`devault` creates a sparse LUKS2 container, enrolls a FIDO2 `hmac-secret` security key and formats the contents as Btrfs with Zstandard compression. It uses UDisks2 to attach, unlock and mount the archive, without a dedicated privileged helper.

The archive format is **standard LUKS2 + Btrfs**, not proprietary. Its LUKS2 header contains the two unlock paths. No sidecar file or running `devault` service is required for emergency recovery with the independent recovery passphrase.

> **Status: experimental v0.9.** Derived from the tested `vault` prototype. Its shell syntax and command interface have been smoke-tested, not independently security-audited. Test both unlock methods and manual rescue on disposable data before storing irreplaceable files.

## Installation

On Debian, install dependencies from a **ROOT** shell:

```sh
apt update
apt install bash cryptsetup udisks2 fido2-tools btrfs-progs jq util-linux coreutils libglib2.0-bin
```

Use a FIDO2 key supporting `hmac-secret`, PIN and physical presence. Your ordinary user must be authorized to access that key and perform the relevant UDisks2/polkit operations.

Install from a **USER** shell:

```sh
install -Dm755 devault "$HOME/.local/bin/devault"
```

Ensure `$HOME/.local/bin` is on your `PATH`.

## Quick start (USER)

```sh
devault create "$HOME/secrets.luks" 8G
devault open "$HOME/secrets.luks"
devault status "$HOME/secrets.luks"
devault close "$HOME/secrets.luks"
```

`create` enrolls FIDO2 and prompts for an **independent recovery passphrase**. The archive is closed at the end of creation.

`open` normally tries the FIDO2 key first and falls back to the recovery passphrase. To skip the key:

```sh
devault open "$HOME/secrets.luks" --recovery
```

After opening, the program prints the path of a convenient symlink beside the archive: for `secrets.luks`, ordinarily `secrets/`. The real UDisks2 mount normally resides under `/run/media/`. Closing removes a matching symlink without disturbing unrelated links.

## Commands

| Command | Description |
| --- | --- |
| `devault create FILE [SIZE]` | Create a new sparse archive (default 1G, units K/M/G/T); never overwrite. |
| `devault open FILE` | Attach loop, unlock, mount and create a convenience symlink. |
| `devault open FILE --recovery` | Unlock with recovery passphrase only. |
| `devault status FILE` | Show loop, mapper, filesystem mount and symlink state. |
| `devault close FILE` | Unmount, lock and release the loop device. |

Run devault as an ordinary user. The archive must be a user-owned regular file, not a symlink. If the file does not end in `.luks` the convenience link normally has the suffix `.mount`.

## Why this approach?

Linux already provides the pieces: LUKS2 via cryptsetup, FIDO2 `hmac-secret` via libfido2, and authorized storage operations via UDisks2. However, ordinary UDisks2 unlocking does not yet directly activate the enrolled FIDO2 token. devault reconstructs the hardware-derived LUKS passphrase in userspace and sends it to UDisks2 through stdin.

The benefits are a single portable image, no invented encryption primitive, no privileged custom service, and straightforward rescue using ordinary Linux utilities. [Design](docs/DESIGN.md) explains the tradeoffs; [Upstream](docs/UPSTREAM.md) tracks native UDisks2 support.

## On-disk structure

```text
secrets.luks (sparse regular file)
└── LUKS2 header
    ├── keyslot 0: independent recovery passphrase
    ├── keyslot 1: FIDO2 hmac-secret-derived passphrase
    └── token: systemd-fido2-like metadata (not the secret)
        └── Btrfs filesystem with zstd compression
```

**The independent recovery passphrase is essential.** The script creates token metadata resembling systemd's format, but native plugin interoperability is not guaranteed. Recovery keyslot 0 needs no token, script, GNOME, UDisks2, or even the original user account. See [manual recovery](docs/RECOVERY.md).

Back up the **entire** archive and retain the recovery passphrase separately. A securely stored LUKS2 header backup is advisable. Remember that sparse files can grow to their logical size.

## Documentation

- [Design and rationale](docs/DESIGN.md)
- [Manual recovery without devault](docs/RECOVERY.md)
- [Security model and limitations](docs/SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Testing](docs/TESTING.md)
- [Native FIDO2 support upstream](docs/UPSTREAM.md)
- [Contributing](CONTRIBUTING.md)

## License and acknowledgements

Licensed under **GNU General Public License v3.0**; see [LICENSE](LICENSE). Companion project to [devoid](https://github.com/devoid-of-void/devoid). Developed with assistance from ChatGPT (OpenAI). Neither this project nor its authors are affiliated with systemd, UDisks2 or the FIDO Alliance.
