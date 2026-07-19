# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Pinned AnoCrypto-C Contract

AnoCrypto-C is an external generic C99 cryptographic module. Enterprise consumes
its installed CMake package and public headers; it does not copy product formats
or orchestration into AnoCrypto-C.

## Dependency identity

| Field | Required value |
|---|---|
| Repository | `anocrypto-c` |
| Reviewed source commit | `89e16a261ab7696d9489167d7403d9f2c704629e` |
| Source artifact SHA-256 | `18aa9050a808e4d541b2a6a10e91aa8e51367b95962b90db2183e26377bdbac1` |
| Runtime identity | `0.1.0-p3-05-scrypt-fixed-profile` |
| CMake package version | `0.1.0` |
| Package/target | `AnoCryptoC` / `AnoCryptoC::AnoCryptoC` |
| Public headers/symbols | `16` / `80` |
| Symbol-version lines | `ANOCRYPTO_C_0` through `ANOCRYPTO_C_4` |
| Retained compatibility | P1-29 and all prior ABI lines |
| License | `MPL-2.0` |

## Dependency availability at reintegration

The required reviewed commit and matching source artifact were not available in
the local AnoCrypto-C repository, upstream Git, or the inspected source
artifacts. Development revision
`c101c9655f881044c14d8efbc20ea94a2e84f30b` reports the required runtime and was
used only for compatibility testing. It is not an approved substitute for the
pinned commit or digest. Configuration with the pinned expected commit rejects
that development package, as required.

Package discovery is exact:

```cmake
find_package(AnoCryptoC 0.1.0 EXACT CONFIG REQUIRED)
```

Configuration additionally requires the expected runtime identity and reviewed
commit. A package reporting an unknown or different identity fails closed unless
the explicitly test-only unknown-commit override is used. That override is not
provenance or release approval.

## Public dependency surface

Enterprise uses only installed public headers:

```text
anocrypto/ac_status.h
anocrypto/ac_module.h
anocrypto/ac_selftest.h
anocrypto/ac_version.h
anocrypto/ac_build.h
anocrypto/ac_hash.h
anocrypto/ac_hmac.h
anocrypto/ac_random.h
anocrypto/ac_key.h
anocrypto/ac_kdf.h
anocrypto/ac_aead.h
```

Private AnoCrypto-C headers and source files are outside the contract.

## Required capability mapping

| Enterprise primitive requirement | AnoCrypto-C public service |
|---|---|
| SHA-256 | `ano_crypto_hash_digest` |
| HMAC-SHA-256 | `ano_crypto_hmac_compute` |
| HKDF-SHA-256 | `ano_crypto_hkdf_sha256` |
| random/key/token bytes | public random context API |
| fixed `SKP1` v1 scrypt profile | `ano_crypto_scrypt_derive_key` |
| AES-256-GCM one-shot | one-shot encrypt/decrypt API |
| AES-256-GCM streaming | stream context API |
| AES key lifecycle | in-memory block-cipher CSP handles |

The scrypt adapter accepts only `N=32768`, `r=8`, `p=1`, a 32-byte result and
the 64 MiB product ceiling. Enterprise allocates the exact caller-owned
workspace required by AnoCrypto-C, removes it on every exit, and performs no
silent parameter substitution.

AES-256-GCM uses 32-byte keys, 12-byte nonces and 16-byte tags. Key material is
imported as an in-memory block-cipher CSP handle and destroyed after use. The
streaming context receives a key snapshot during initialization; Community owns
packet/file buffering and commits no unauthenticated plaintext.

## Lifecycle and status

Enterprise initializes the module, verifies startup self-test, operational
state, runtime identity, build identity and configured commit before exposing
profile readiness. Shutdown and repeated lifecycle calls preserve the existing
contract. Native operation statuses are mapped without treating an error as
success; authentication failure remains distinct from invalid input and backend
failure.

## Product boundary

AnoCrypto-C owns only generic primitives, module state, CSP lifecycle and stable
C ABI. Enterprise/Community continue to own:

- `SKT1`, `SKF1`, `SKP1` parsing and serialization;
- nonce composition, AAD composition and output-commit policy;
- path handling, temporary files and transactional replacement;
- capability reporting, backend selection and no-fallback policy;
- package, provenance, authorization and support decisions.

## Build example

```sh
cmake -S . -B build-native -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=anocrypto-c \
  -DANOSECUREKIT_ENTERPRISE_ENABLE_NATIVE_ANOCRYPTO_C_TESTS=ON \
  -DANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID=0.1.0-p3-05-scrypt-fixed-profile \
  -DANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT=89e16a261ab7696d9489167d7403d9f2c704629e \
  -DAnoCryptoC_DIR=<prefix>/lib/cmake/AnoCryptoC
cmake --build build-native --target enterprise-anocrypto-c-parity-check
```

The completed primitive profile is still non-installable in this repository.
Hosted qualification, signing, trusted provenance, support approval and external
release authorization remain independent blockers.
