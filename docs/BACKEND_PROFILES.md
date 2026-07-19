# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Enterprise Backend Profiles

Exactly one backend is selected at configure time:

```text
ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl
ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=anocrypto-c
```

Runtime plugin discovery and automatic fallback are not supported.

## OpenSSL

The OpenSSL profile uses the bundled exact Community v0.4.0 source and its
OpenSSL implementation. Existing local install/export and internal delivery
qualification remain available, subject to the repository's release gates.

## AnoCrypto-C

The AnoCrypto-C profile requires:

- installed `AnoCryptoC::AnoCryptoC` version `0.1.0`;
- runtime identity `0.1.0-p3-05-scrypt-fixed-profile`;
- reviewed commit `89e16a261ab7696d9489167d7403d9f2c704629e`;
- full seven-capability provider and runtime masks;
- no OpenSSL source, symbol, or runtime dependency in the selected profile.

The adapter surface is complete for the current AnoSecureKit Community product
operations but remains build-tree-only. Local compatibility used unapproved
development revision `c101c9655f881044c14d8efbc20ea94a2e84f30b`; the required
reviewed source and digest were unavailable. Installation, export, CPack and
customer delivery stay disabled until exact package, provenance, hosted,
signing and release authorization gates are approved.

## Required capability set

```text
sha256
hmac-sha256
hkdf-sha256
random
scrypt
aes256-gcm
aes256-gcm-stream
```

Configuration fails when any capability is missing. No missing operation may be
routed to OpenSSL.
