# Upstream UDisks2 FIDO2 integration

The preferred architecture is token-aware LUKS2 activation in **libblockdev and UDisks2**, enabling FIDO2 unlock from GNOME Files, `udisksctl` and other desktop clients without a separate secret-derivation shell workflow.

Relevant references:

- [udisks issue #1317](https://github.com/storaged-project/udisks/issues/1317): ordinary unlocking does not currently support a FIDO2-only keyslot.
- [libblockdev](https://github.com/storaged-project/libblockdev): maintainers identified this as the desired starting point for implementation.
- [Experimental FIDO2 UDisks2 branch](https://github.com/LeReverandNox/udisks/tree/feat_fido2): proposes `UnlockWithTokens()` and `EnrolledTokenTypes`. It has not been accepted as an upstream release.

The upstream maintainer described the feature as desired but constrained by development time, not prohibited by technical design. The long-term implementation should support token discovery, PIN/touch prompting, activation and eventually enrollment/management, with tests and stable D-Bus errors.

**Important compatibility caveat:** devault writes its own `systemd-fido2`-like token metadata and reproduces the HMAC secret itself. Do not assume a future native plugin can unlock an existing devault archive until proven through interoperable tests. Ordinary polkit permission for loop setup also remains a separate concern.
