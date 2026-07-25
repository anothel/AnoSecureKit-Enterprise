# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# AnoCrypto-C Parity Status

P3-06 implements the previously approved AnoSecureKit primitive parity surface.
Local compatibility validation used development revision
`c101c9655f881044c14d8efbc20ea94a2e84f30b`, which reports AnoCrypto-C
`0.1.0-p3-05-scrypt-fixed-profile`. This is the actual Enterprise validation
identity, not the P3-06 reviewed contract or the later Phase 1 archive.

## Current result

```text
Enterprise OpenSSL profile
= Community v0.4.0 product behavior through OpenSSL

Enterprise AnoCrypto-C profile
= Community v0.4.0 product behavior through AnoCrypto-C primitives
  for SHA-256, HMAC-SHA-256, HKDF-SHA-256, random, fixed-profile scrypt,
  AES-256-GCM one-shot and AES-256-GCM streaming
```

The runtime capability mask contains all seven required bits. Exact `SKT1`,
`SKF1` and `SKP1` fixtures and product round trips pass. Missing service routing
and OpenSSL fallback are prohibited.

## Implemented and locally exercised engineering gaps

- HKDF-SHA-256 and exact `SKF1` info bytes;
- AES-256-GCM one-shot for packet, file and key-wrap paths;
- AES-256-GCM streaming for `SKT1`/file chunks;
- fixed `SKP1` v1 scrypt profile and resource ceiling;
- complete runtime capability declaration;
- no-OpenSSL runtime dependency inspection;
- wrong-key file-open no-output behavior.

## Archived limitations and conditional reopen gates

Parity completion does not establish:

- Linux installed-package consumption: the development package exports
  `Threads::Threads` without loading the `Threads` dependency;
- hosted Linux/Windows/macOS qualification and review;
- trusted package/source provenance acceptance;
- repository or production artifact signing;
- timestamping and attestation verification;
- customer support transition and release authorization;
- formal KCMVP or other validation work.

The P3-06 reviewed contract remains
`89e16a261ab7696d9489167d7403d9f2c704629e` with source SHA-256
`18aa9050a808e4d541b2a6a10e91aa8e51367b95962b90db2183e26377bdbac1`.
AnoCrypto-C Phase 1 archive
`98f544a574f70b387c300f171243b4e87174937a` is retained externally;
Enterprise validation against it was `NOT_RUN_AND_NOT_CLAIMED`.

The AnoCrypto-C profile therefore remains an internal build-tree qualification
profile, not an installable or externally releasable product package. All
remaining items are archived or not selected; active next work is none.
