# Contributing to devault

devault is security-sensitive shell orchestration. Prefer small, reviewed changes over cleverness. Open an issue describing the failure, hardware and distribution, then propose a focused pull request.

- Preserve the **standard LUKS2 + Btrfs** storage format and the independent recovery-passphrase route.
- Never silently change the keyslot layout, token metadata or FIDO2 derivation without documenting migration and compatibility.
- Never add real archive files, credentials, PINs or header backups to Git.
- Keep normal commands unprivileged and never introduce `sudo` or a setuid helper for routine operations.
- Preserve safe cleanup order: unmount, lock mapper, release loop. Do not detach an in-use device.
- Test `bash tests/static.sh` and use a disposable FIDO2 device/archive for integration testing. Follow [TESTING.md](docs/TESTING.md).
- Review [SECURITY.md](docs/SECURITY.md) and [RECOVERY.md](docs/RECOVERY.md) when changing authentication or header handling.
- Explain behavioral changes in [CHANGELOG.md](CHANGELOG.md).

Contributions are accepted under the repository's [GPL-3.0 license](LICENSE). No secrets, identifying device logs or live encrypted personal archives in public reports.
