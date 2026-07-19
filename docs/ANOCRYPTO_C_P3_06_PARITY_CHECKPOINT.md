# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# P3-06 AnoCrypto-C Enterprise Parity Checkpoint

Status: `REINTEGRATED_LOCAL_COMPATIBILITY_PASS_RELEASE_BLOCKED`

## Inputs

- AnoSecureKit Enterprise recovery input baseline:
  `3a62318fce27985d091bb5445fc59d0fca7033a2`
- Reintegration baseline: `a15f10fccf25905c97a7098a2d1956ae0141247e`
- AnoSecureKit Community exact revision:
  `694459ebe497d15ba75ef76a52fa7c36ddd7bcce`
- AnoSecureKit Community Git tree:
  `5478a5c37e96aa1017f8f4604234de48c1115d7c`
- AnoSecureKit Community source ZIP SHA-256:
  `a9b1e0bf6baca93509c4706b38066a539c5324151b338859063ebb8cf3cffeb5`
- AnoCrypto-C runtime: `0.1.0-p3-05-scrypt-fixed-profile`
- AnoCrypto-C reviewed commit:
  `89e16a261ab7696d9489167d7403d9f2c704629e`
- AnoCrypto-C source SHA-256:
  `18aa9050a808e4d541b2a6a10e91aa8e51367b95962b90db2183e26377bdbac1`

## Implemented adapter surface

- SHA-256
- HMAC-SHA-256
- HKDF-SHA-256
- secure random, generated keys and tokens
- fixed `SKP1` v1 scrypt profile
- AES-256-GCM one-shot
- AES-256-GCM streaming

The runtime and provider masks contain exactly these seven capabilities. No
OpenSSL fallback exists.

## Required compatibility evidence

- RFC 5869 HKDF case through the Community API;
- exact `SKT1` one-shot and streaming fixture compatibility;
- exact key-wrap fixture compatibility;
- exact `SKF1` known-file open;
- exact `SKP1` password-file open;
- generated packet/file/password round trips;
- wrong-key authentication failure with no committed output or temporary file;
- installed AnoCrypto-C identity checks;
- source/package boundary and Linux dependency inspection.

## Claims not made

- no customer install/export package;
- no hosted lane success;
- no repository or production signing;
- no timestamp or trusted attestation;
- no external release authorization;
- no KCMVP validation or active submission.

## Validation record

Fresh local validation used unapproved development revision
`c101c9655f881044c14d8efbc20ea94a2e84f30b`; it did not substitute or approve
the unavailable reviewed commit and digest.

- Windows MSVC Release static and shared AnoCrypto-C suites: `88/88` each;
- Windows MSVC Release static and shared Enterprise suites: `17/17` each, with
  the eight-test P3 parity target passing;
- WSL Ubuntu 26.04 GCC Release static and Clang Release shared AnoCrypto-C
  suites: `88/88` each;
- WSL GCC static and Clang shared Enterprise suites: `17/17` each, with the
  eight-test P3 parity target passing;
- WSL Clang ASan/UBSan AnoCrypto-C primitive tests and the Enterprise eight-test
  P3 parity target: pass;
- production-style native-tests-disabled build: exact seven capabilities ready,
  no installed files and no OpenSSL dependency;
- pinned-commit negative check: the development package is rejected;
- Linux installed-package smoke: blocked because the development package
  exports `Threads::Threads` without calling `find_dependency(Threads)`.

The exact Community v0.4.0 source was reconstructed as Git tree
`5478a5c37e96aa1017f8f4604234de48c1115d7c`; Windows static and shared Community
release preflights passed `124/124` main tests and `124/124` external-provider
parity tests.

Hosted, signing, provenance, support and authorization results remain
unavailable regardless of local compatibility. Customer release remains denied.
