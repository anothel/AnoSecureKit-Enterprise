# Enterprise Backend Profiles

AnoSecureKit Enterprise is intended to cover the AnoSecureKit Community
functionality while adding proprietary policy, diagnostics, packaging, and
customer-delivery features. Cryptographic provider selection is explicit.

## Current Implementation Truth

The current Enterprise `0.1.0` scaffold links the bundled Community final target:

```text
anosecurekit::anosecurekit
```

That target is OpenSSL-backed. Therefore the current runnable scaffold is an
OpenSSL-based development baseline, not an implemented AnoCrypto-C profile.

The existing boolean `ANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO` and generic
`anocrypto` package lookup do not replace the Community OpenSSL provider. They
must not be documented or shipped as a working AnoCrypto-C backend profile.

## Target Profiles

```text
Enterprise OpenSSL profile
= Community-compatible common behavior
+ OpenSSL provider
+ Enterprise layer

Enterprise AnoCrypto-C profile
= Community-compatible common behavior
+ proprietary AnoCrypto-C C++ provider
+ external AnoCryptoC::AnoCryptoC
+ Enterprise layer
```

A future configuration surface should use one explicit value, for example:

```text
ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl
ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=anocrypto-c
```

The existing boolean option should be removed or migrated after the Community
provider seam is available.

## OpenSSL Profile

The OpenSSL profile:

- uses the verified Community implementation/provider;
- covers the full Community public API and format behavior;
- adds Enterprise-owned policy, diagnostics, packaging, and support surfaces;
- includes applicable Community/MPL-2.0 and OpenSSL notices in delivery packs;
- must identify itself as the OpenSSL profile and must not imply KCMVP status.

## AnoCrypto-C Profile

The AnoCrypto-C profile:

- discovers the external package with `find_package(AnoCryptoC CONFIG REQUIRED)`;
- requires the exact imported target `AnoCryptoC::AnoCryptoC`;
- links a proprietary Enterprise C++ adapter, not Community's OpenSSL provider;
- initializes the module and checks self-test/operational state;
- verifies all capabilities required by the selected product surface;
- reports provider/module name and version in diagnostics;
- contains no silent OpenSSL fallback.

AnoCrypto-C source, headers copied from its repository, binaries, or package
payloads are not stored in this repository. They are provided separately under
their own release and license terms.

## Capability Gate

The Community v1 surface currently requires, directly or indirectly:

- SHA-256;
- HMAC-SHA-256;
- HKDF-SHA-256;
- cryptographically secure random bytes;
- AES-256-GCM one-shot and streaming behavior;
- scrypt for `SKP1`;
- primitives sufficient for key wrapping and file sealing.

The inspected AnoCrypto-C pre-release covered module lifecycle/self-test,
SHA-2, HMAC, HMAC_DRBG, and random service, but did not yet cover every required
KDF/AEAD/password-KDF operation. Until parity exists, the AnoCrypto-C profile is
non-production or exposes only an explicitly reduced unsupported surface.

Missing operations must not be delegated to OpenSSL while the product reports
`anocrypto-c`.

## Format Policy

`SKT1`, `SKF1`, and `SKP1` may be shared across profiles only when algorithm and
parameter semantics are exactly compatible. If an AnoCrypto-C/KCMVP-oriented
profile requires different algorithms or policies, introduce a new format or
version instead of changing v1 meaning.

## Required Diagnostics

Every Enterprise build must report:

- Enterprise version;
- selected backend profile;
- actual provider/module name and version;
- operational and self-test state where applicable;
- supported and missing capabilities;
- production or development qualification status.

A compile definition alone is not proof that a backend is available.

## Required Tests

Before an Enterprise profile is releasable:

- run the same public API behavior suite for the profile;
- verify format fixtures and negative/authentication behavior;
- test invalid profile and missing/malformed package rejection;
- test capability fail-closed behavior;
- verify installed package/consumer use;
- verify the AnoCrypto-C profile has no OpenSSL production linkage;
- generate profile-specific notices, SBOM, checksums, and provenance.
