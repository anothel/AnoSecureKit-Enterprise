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
qualification remain available. Engineering is closed and frozen; hosted
qualification was not run and customer release remains blocked.

## AnoCrypto-C

The AnoCrypto-C profile requires:

- installed `AnoCryptoC::AnoCryptoC` version `0.1.0`;
- runtime identity `0.1.0-p3-05-scrypt-fixed-profile`;
- reviewed commit `89e16a261ab7696d9489167d7403d9f2c704629e`;
- full seven-capability provider and runtime masks;
- no OpenSSL source, symbol, or runtime dependency in the selected profile.

The adapter surface is complete for the current AnoSecureKit Community product
operations but remains build-tree-only. The reviewed P3-06 contract is
`89e16a261ab7696d9489167d7403d9f2c704629e`; actual Enterprise validation
used development revision `c101c9655f881044c14d8efbc20ea94a2e84f30b`.
AnoCrypto-C Phase 1 archive `98f544a574f70b387c300f171243b4e87174937a`
was not revalidated and is not the Enterprise pin. Installation, export, CPack,
and customer delivery stay disabled. No follow-on work is selected.

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

The current AnoCrypto-C installed-package limitation is an exported
`Threads::Threads` target without `find_dependency(Threads)`. It must be
resolved before any install/export or customer-release reopening.
