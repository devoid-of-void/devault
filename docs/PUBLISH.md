# Release maintenance

The repository is hosted at [devoid-of-void/devault](https://github.com/devoid-of-void/devault).

Before preparing a release:

1. Review source, manual recovery instructions and the independent recovery keyslot format.
2. Run the non-destructive test suite: `bash tests/static.sh`.
3. Test on disposable archives with FIDO2 PIN/touch **and** explicit `--recovery`.
4. Independently recover a disposable archive using [RECOVERY.md](RECOVERY.md) without devault installed.
5. Update [CHANGELOG.md](../CHANGELOG.md) and relevant docs.
6. Check for accidental sensitive data (`.luks` images, real keys, metadata backups, logs).
7. Only then create a signed tag/release and describe tested distributions and limitations.

The checked-in automated tests are not a cryptographic audit. Do not claim native systemd token interoperability until verified experimentally. Respect the existing GPL-3.0 [LICENSE](../LICENSE).
