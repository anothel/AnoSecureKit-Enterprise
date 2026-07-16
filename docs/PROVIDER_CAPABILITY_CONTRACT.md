# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Enterprise Provider Capability Contract

AnoSecureKit Enterprise treats backend selection as a product profile, not as a best-effort runtime preference.

## Required production capabilities

The AnoCrypto-C production profile must provide the complete Community v1 primitive surface:

```text
sha256
hmac-sha256
hkdf-sha256
random
scrypt
aes256-gcm
aes256-gcm-stream
```

The list covers the primitives required by the current Community public API and the `SKT1`, `SKF1`, and `SKP1` formats. It does not assert that the external AnoCrypto-C package currently implements every item.

The pinned `0.1.0-p1-33-release-rehearsal` baseline is ready to integrate for
module lifecycle, self-test reporting, version/build identity, SHA-256,
HMAC-SHA-256, HMAC_DRBG-SHA-256, and platform-backed random. It also implements
SHA-384/SHA-512, matching HMAC variants, AES-CBC, AES-CMAC, and in-memory key
handles. These additional services do not satisfy the missing product
capabilities.

## Provider target metadata

The proprietary provider adapter must be a non-imported CMake `OBJECT_LIBRARY` and set:

```cmake
set_property(TARGET <provider> PROPERTY
  ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID "anocrypto-c")
set_property(TARGET <provider> PROPERTY
  ANOSECUREKIT_ENTERPRISE_PROVIDER_CAPABILITIES
  "sha256;hmac-sha256;hkdf-sha256;random;scrypt;aes256-gcm;aes256-gcm-stream")
target_link_libraries(<provider> PRIVATE AnoCryptoC::AnoCryptoC)
```

Configuration fails when the identity, capability list, direct module link, target type, or module package contract is missing.

## Fail-closed rule

A partial AnoCrypto-C provider is not promoted to the production profile. Missing services are not sent to OpenSSL and are not represented as available. Development work may implement capabilities incrementally, but production profile configuration remains blocked until the complete requirement set is met.

## Runtime gate implemented as a contract

The static CMake capability declaration is only the first gate. Enterprise now also defines runtime contract version `1` and verifies:

- AnoCrypto-C module initialization;
- startup self-test result;
- operational state;
- runtime module version and build identity;
- service availability reported by the module;
- error/status translation;
- absence of OpenSSL production linkage in the AnoCrypto-C profile.

The runtime adapter is selected at link time and independently reports a
capability mask. The production AnoCrypto-C lifecycle implementation uses the
pinned external public API and reports mask `0`; cryptographic service adapters
remain pending. Tests retain mock runtime adapters for failure paths and use the
installed package for the production lifecycle path. See
`PROVIDER_RUNTIME_CONTRACT.md`.

HKDF-SHA-256, scrypt, AES-256-GCM, streaming AEAD, and key wrapping are absent
from the pinned baseline and block full parity. They must not be declared in an
actual adapter capability mask until implemented and verified.

Static or mock metadata must not be treated as KCMVP or FIPS validation evidence.
