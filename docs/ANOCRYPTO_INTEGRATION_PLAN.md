# AnoCrypto-C Backend Integration Plan

AnoCrypto-C integration is an explicit Enterprise cryptographic-provider
profile, not an optional marketing add-on and not a hybrid OpenSSL fallback.

AnoCrypto-C itself is managed outside this repository. Enterprise owns only the
C++ adapter, profile selection, policy, diagnostics, compatibility tests, and
customer packaging boundary.

## Current Blocker

The current Enterprise target always links the Community final target, which is
OpenSSL-backed. The existing boolean option and generic `anocrypto` lookup only
attempt to add another library; they do not replace the backend.

Do not implement the provider adapter until Community exposes a verified
internal/build-tree provider seam.

## External Package Contract

Recorded contract:

```cmake
find_package(AnoCryptoC CONFIG REQUIRED)
```

Required imported target:

```text
AnoCryptoC::AnoCryptoC
```

Public include root supplied by that package:

```text
include/anocrypto
```

Do not use the obsolete expected names `anocrypto::anocrypto` or `anocrypto`.
Do not search for or add a source tree under `third_party/anocrypto`.

## Proposed Enterprise Selection

Replace the legacy boolean after the provider seam exists with an explicit
profile value such as:

```text
ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl
ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=anocrypto-c
```

Configuration must reject unknown values. The AnoCrypto-C value must require the
exact external package and target before any availability macro is defined.

## Integration Gate

1. Locate the exact external package and imported target.
2. Link a proprietary Enterprise C++ provider adapter.
3. Initialize the AnoCrypto-C module.
4. Run or verify required startup self-tests.
5. Require the module to be operational.
6. Query and verify every capability required by the selected product surface.
7. Map AnoCrypto-C status codes to stable AnoSecureKit public errors.
8. Report provider/module version, state, and capabilities in diagnostics.
9. Run the common AnoSecureKit API/format/negative test suite.
10. Verify the final AnoCrypto-C profile has no OpenSSL production linkage.

A compile definition or discovered package alone does not mean the profile is
available.

## Current Capability Gap

The inspected AnoCrypto-C pre-release provided module lifecycle/self-test,
SHA-2, HMAC, HMAC_DRBG, and public random service. Full Community parity still
requires confirmed implementations and evidence for at least:

- HKDF-SHA-256;
- AES-256-GCM one-shot operations;
- AEAD streaming state;
- primitives required by key wrapping and `SKF1`;
- scrypt or a versioned replacement policy for `SKP1`.

Until all required capabilities exist, the AnoCrypto-C profile is either
non-production or has an explicitly reduced unsupported surface. It must never
send missing operations to OpenSSL while reporting itself as AnoCrypto-C.

## Format Gate

Reuse `SKT1`, `SKF1`, and `SKP1` only when algorithms, parameters, AAD, nonce,
tag, and KDF semantics are exactly compatible with Community v1. If a validated
profile requires different semantics, create a new Enterprise format/version.

## Evidence and Delivery Gate

- Known-answer tests for every provider primitive.
- Cross-provider compatibility tests where semantics match.
- Stable byte-level fixtures and negative tests.
- Module self-test and failure-state tests.
- Supported OS/CPU/compiler/profile matrix.
- Profile-specific SBOM, notices, checksums, provenance, and module metadata.
- Confirmed separate commercial license and redistribution terms.
- Security and legal review before customer delivery.
