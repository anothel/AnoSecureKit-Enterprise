# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Pinned AnoCrypto-C Contract

AnoCrypto-C is an external dependency. Enterprise does not copy, vendor, or
relicense its source.

## Dependency identity

| Field | Required value |
|---|---|
| Repository commit | `cf0f3c425dd265c7509fb64a6123db97f71055dd` |
| CMake package version | `0.1.0` |
| Runtime identity | `0.1.0-p1-33-release-rehearsal` |
| Package | `AnoCryptoC` |
| Imported target | `AnoCryptoC::AnoCryptoC` |
| Include root | `include/anocrypto` |
| Public symbol count | `69` |
| Build identity ABI | `1` |
| License | `MPL-2.0` |
| Approved package/archive SHA-256 | `TBD-NOT-APPROVED` |

Package discovery is exact:

```cmake
find_package(AnoCryptoC 0.1.0 EXACT CONFIG REQUIRED)
```

The CMake version check is not sufficient. Package intake must compare the
installed package or approved archive with the recorded SHA-256 and source
commit. The production lifecycle adapter rejects a runtime version other than
`0.1.0-p1-33-release-rehearsal`, validates build identity ABI `1`, and retains
module version/build fingerprint for diagnostics. Until an approved digest
replaces `TBD-NOT-APPROVED`, no package satisfies the delivery contract.

The local AnoCrypto-C repository root file `AnoCrypto-C.zip` is untracked and
is not an approved package. Only a verified installed package or separately
approved archive may be used.

## Production lifecycle adapter and opt-in harness

Enterprise owns the production lifecycle adapter under
`src/providers/anocrypto_c`. The opt-in harness compiles that same adapter
source against the installed package. Enable the harness only with:

```cmake
-DANOSECUREKIT_ENTERPRISE_ENABLE_NATIVE_ANOCRYPTO_C_TESTS=ON
-DANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID=0.1.0-p1-33-release-rehearsal
-DANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT=cf0f3c425dd265c7509fb64a6123db97f71055dd
-DAnoCryptoC_DIR=<installed-prefix>/lib/cmake/AnoCryptoC
```

The option defaults to `OFF`. Enabling it requires both expected identity
values and performs exact config-package discovery. It does not use
`FetchContent`, a source checkout, or `AnoCrypto-C.zip`.

The installed package must expose a non-empty commit matching the configured
pin. A package reporting `unknown` fails unless the explicitly development-only
`ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_FOR_TESTS=ON`
override is set. That override permits native development only, is not
delivery provenance or approval, and cannot enable AnoCrypto-C packaging.

## Required public headers

Lifecycle and identity:

```text
anocrypto/ac_status.h
anocrypto/ac_module.h
anocrypto/ac_selftest.h
anocrypto/ac_version.h
anocrypto/ac_build.h
```

Initial services:

```text
anocrypto/ac_hash.h
anocrypto/ac_hmac.h
anocrypto/ac_random.h
```

Adapters use these specific headers. The umbrella `anocrypto/anocrypto.h` is
unnecessary for the initial integration and must not expand the dependency
surface implicitly. Private AnoCrypto-C headers are outside this contract.

## Lifecycle contract

Required symbols:

```text
ano_crypto_module_init
ano_crypto_module_shutdown
ano_crypto_module_get_state
ano_crypto_module_get_last_error
ano_crypto_module_require_operational
ano_crypto_selftest_get_last_status
ano_crypto_version_string
ano_crypto_build_identity
ano_crypto_build_fingerprint
```

Required order:

```text
optional version/build query
-> ano_crypto_module_init(NULL)
-> self-test status == ANO_CRYPTO_OK
-> module state == ANO_CRYPTO_MODULE_STATE_OPERATIONAL
-> ano_crypto_module_require_operational() == ANO_CRYPTO_OK
-> pinned runtime/build identity verification
-> cryptographic services
-> ano_crypto_module_shutdown()
```

Initialization automatically runs startup self-tests. Error state is sticky for
the process, and shutdown does not recover it. Repeated initialization while
operational and repeated shutdown succeed. Normal shutdown may be followed by
reinitialization. Enterprise owns lifecycle ordering and prohibits concurrent
initialize, shutdown, and explicit self-test operations.

The native harness verifies the production adapter's clean starting snapshot,
startup self-test, operational gate, repeated initialization, shutdown,
reinitialization, repeated shutdown, runtime identity, build identity ABI,
fingerprint, commit policy, identity-mismatch rejection, and the SHA-256 plus
HMAC-SHA-256 capability mask against the installed package.

Native module states map without loss:

| AnoCrypto-C | Enterprise |
|---|---|
| `ANO_CRYPTO_MODULE_STATE_UNINITIALIZED` | `uninitialized` |
| `ANO_CRYPTO_MODULE_STATE_SELF_TEST_RUNNING` | `self_test_running` |
| `ANO_CRYPTO_MODULE_STATE_OPERATIONAL` | `operational` |
| `ANO_CRYPTO_MODULE_STATE_ERROR_STATE` | `error` |
| `ANO_CRYPTO_MODULE_STATE_SHUTDOWN` | `shutdown` |

## Operation status contract

Lifecycle status remains separate from per-operation status. The production
operation-status mapper under `src/providers/anocrypto_c` preserves these
mappings without calling a cryptographic service or mutating lifecycle state:

| AnoCrypto-C | Enterprise operation status |
|---|---|
| `ANO_CRYPTO_OK` | `success` |
| `ANO_CRYPTO_ERR_INVALID_ARGUMENT` | `invalid_argument` |
| `ANO_CRYPTO_ERR_BUFFER_TOO_SMALL` | `buffer_too_small` |
| `ANO_CRYPTO_ERR_UNSUPPORTED_ALGORITHM`, `ANO_CRYPTO_ERR_UNSUPPORTED_PARAMETER`, `ANO_CRYPTO_ERR_NOT_IMPLEMENTED` | `unsupported` |
| `ANO_CRYPTO_ERR_NOT_APPROVED_IN_MODE` | `not_approved` |
| `ANO_CRYPTO_ERR_SELF_TEST_FAILED`, `ANO_CRYPTO_ERR_NOT_INITIALIZED`, `ANO_CRYPTO_ERR_FATAL_STATE` | `not_operational` |
| `ANO_CRYPTO_ERR_ENTROPY_SOURCE_FAILED` | `entropy_failure` |
| `ANO_CRYPTO_ERR_DRBG_RESEED_REQUIRED` | `reseed_required` |
| `ANO_CRYPTO_ERR_AUTHENTICATION_FAILED` | `authentication_failed` |
| `ANO_CRYPTO_ERR_INTEGRITY_CHECK_FAILED` | `integrity_failure` |
| `ANO_CRYPTO_ERR_RESOURCE_EXHAUSTED` | `resource_exhausted` |
| `ANO_CRYPTO_ERR_INTERNAL_ERROR` or unknown | `internal_error` |

When returned by lifecycle initialization, `ANO_CRYPTO_ERR_SELF_TEST_FAILED`
remains a lifecycle `self_test_failed` result and places the module in a
non-operational error state. When observed as a direct service-operation
result, the operation mapper reports `not_operational`.

The production lifecycle conversion and service-operation conversion are
separate functions. Unknown native states map to Enterprise `error`; unknown
lifecycle statuses and unknown operation statuses map to `internal_error`.
Compile-time assertions pin every known numeric native status, and the opt-in
native test covers every known value plus reviewed unknown cast values.

## SHA-256 service contract

SHA-256 is the first connected native service. The Enterprise provider calls
the public AnoCrypto-C one-shot API exactly as declared by `ac_hash.h`:

```c
ano_crypto_status_t ano_crypto_hash_digest(
    ano_crypto_hash_algorithm_t algorithm,
    const uint8_t *input,
    size_t input_len,
    uint8_t *out,
    size_t out_len,
    size_t *out_written);
```

The adapter passes `ANO_CRYPTO_HASH_ALG_SHA256`, a 32-byte output buffer, and
requires exactly 32 bytes written. It calls the established operational gate
before the hash API. Empty input passes `NULL` with length zero; non-empty input
passes its exact byte span and length. Native results use the operation-status
mapper. Any mapped error or wrong output length becomes the existing public
`anosecurekit::error_code::backend_failure`; no partial digest is returned.

The same public `anosecurekit::sha256` test covers empty input, `abc`, embedded
zero bytes, 257-byte multi-block input, and deterministic 1 MiB input on both
OpenSSL and AnoCrypto-C. It also verifies rejection before initialization and
after shutdown, native validation failures, output-buffer safety, and unknown
status fail-closed behavior.

## HMAC-SHA-256 service contract

The Enterprise provider uses AnoCrypto-C's one-shot raw-key API from
`ac_hmac.h`:

```c
ano_crypto_status_t ano_crypto_hmac_compute(
    ano_crypto_hash_algorithm_t hash_algorithm,
    const uint8_t *key,
    size_t key_len,
    const uint8_t *input,
    size_t input_len,
    uint8_t *out,
    size_t out_len,
    size_t *out_written);
```

The algorithm is `ANO_CRYPTO_HASH_ALG_SHA256` (`1`). The adapter calls the
existing operational gate first, zero-initializes its 32-byte temporary output,
passes raw key/message bytes without key handles, and accepts output only when
the shared operation-status mapper reports success and `out_written == 32`.
Empty key or message uses `NULL` with length zero, as explicitly accepted by the
native contract; a nonzero length always has a non-null pointer. Arbitrary byte
keys are accepted, including embedded zeros and keys below, equal to, or above
the 64-byte SHA-256 block size. Any native error or wrong output length becomes
the existing public `backend_failure`; no partial MAC is returned.

The same public `anosecurekit::hmac_sha256` test passed OpenSSL/AnoCrypto-C
byte-for-byte parity for RFC 4231 cases 1, 2, 3, 4, 6, and 7; empty key/input;
separate empty-key and empty-message cases; embedded-zero binary input; short,
64-byte, and long keys; 257-byte multi-block input; and deterministic 1 MiB
input. Each case runs twice and verifies that key/message buffers are unchanged.
Native negative coverage includes pre-initialization, post-shutdown, invalid
argument, short output, mapped error, unknown status, wrong reported length,
and unchanged output on rejected calls.

## Capability status

Connected through Enterprise native adapters:

- module lifecycle and self-test reporting;
- version and build identity;
- SHA-256;
- raw-key HMAC-SHA-256.

Ready for later native adapter integration:

- HMAC_DRBG-SHA-256 and platform-backed random.

Additional implemented AnoCrypto-C services are SHA-384/SHA-512, matching HMAC
variants, AES-128/192/256-CBC, AES-CMAC, and in-memory key handles. They are not
added to the current Enterprise provider capability mask because they do not
replace missing product requirements.

The SHA-256 and HMAC-SHA-256 adapters use the shared operation-status mapper.
The development runtime reports exactly the `sha256` and `hmac-sha256`
capability bits. Fail-closed stubs for the remaining Community backend symbols
contain no cryptographic implementation and advertise no capability.

Full Enterprise parity remains blocked by missing HKDF-SHA-256, random, scrypt,
AES-256-GCM, streaming AEAD, and key wrapping. Missing services never fall back
to OpenSSL and are never advertised as available.

## Packaging, platforms, and licensing

AnoCrypto-C has shared-package evidence for Linux and Windows. Source branches
exist for Linux, Windows, and Apple platform entropy and synchronization.
Static package consumption remains unverified. Windows and macOS hosted
verification is deferred, as are hosted artifact and provenance checks.

Linux native verification inspects the lifecycle executable, public SHA-256 and
HMAC-SHA-256 test executables, and imported AnoCrypto-C library with `ldd`,
rejecting `libcrypto` or `libssl`. Windows and macOS dependency inspection
remains deferred until a suitable local or hosted package is available.

AnoCrypto-C remains MPL-2.0. Enterprise does not relicense it. Applicable MPL
source and notice obligations must be preserved; private-repository or
commercial status does not remove them. Legal review is required before
customer delivery. This document is an engineering record, not legal advice.

No public forced-KAT-failure hook is approved, so native self-test-failure
injection remains deferred. Existing mock self-test-failure tests remain the
only failure-path evidence.

The proprietary lifecycle adapter, operation-status mapper, SHA-256 provider,
and HMAC-SHA-256 provider are linked into the opt-in build-tree AnoCrypto-C
development profile, which reports exactly `sha256` and `hmac-sha256`. Their
source/header files are not installed or exported, and the profile remains
excluded from CPack, customer archives, and the delivery SBOM. Lifecycle
readiness and two services therefore do not make the complete profile ready.
The AnoCrypto-C production profile remains blocked from customer delivery.
