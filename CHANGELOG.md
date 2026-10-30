# Changelog

## 0.9 (2026-10-30) — initial public prototype

- Renamed the existing working `vault` prototype to **devault**.
- Sparse, portable single-file LUKS2 image and Btrfs with zstd compression.
- Two independent keyslots: recovery passphrase and PIN/touch-protected FIDO2 `hmac-secret`.
- Ordinary-user lifecycle through UDisks2: `create`, `open`, `close` and `status`; explicit `open --recovery`.
- Detect and reuse existing loop/mapping state, coordinated locking, cleanup and loop autoclear.
- Safe convenience symlink beside the archive and symlink state reporting.
- Temporarily disable GNOME automount to avoid desktop races; suppress interactive polkit challenges.
- Manual rescue instructions using standard Linux cryptsetup and Btrfs tools.
- Documentation for security limits, testing, upstream token support and troubleshooting.

**Status:** prototype; requires testing on real FIDO2 hardware and supported Linux desktop setups. No security audit.
