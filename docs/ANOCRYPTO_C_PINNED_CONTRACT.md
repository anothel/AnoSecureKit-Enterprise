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
override is set. That override permits lifecycle development only, is not
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
fingerprint, commit policy, identity-mismatch rejection, and zero capability
mask against the installed package.

Native module states map without loss:

| AnoCrypto-C | Enterprise |
|---|---|
| `ANO_CRYPTO_MODULE_STATE_UNINITIALIZED` | `uninitialized` |
| `ANO_CRYPTO_MODULE_STATE_SELF_TEST_RUNNING` | `self_test_running` |
| `ANO_CRYPTO_MODULE_STATE_OPERATIONAL` | `operational` |
| `ANO_CRYPTO_MODULE_STATE_ERROR_STATE` | `error` |
| `ANO_CRYPTO_MODULE_STATE_SHUTDOWN` | `shutdown` |

## Operation status contract

Lifecycle status remains separate from per-operation status. A future adapter
must preserve these mappings rather than collapse failures into a generic
runtime result:

| AnoCrypto-C | Enterprise operation status |
|---|---|
| `ANO_CRYPTO_OK` | `success` |
| `ANO_CRYPTO_ERR_INVALID_ARGUMENT` | `invalid_argument` |
| `ANO_CRYPTO_ERR_BUFFER_TOO_SMALL` | `buffer_too_small` |
| `ANO_CRYPTO_ERR_UNSUPPORTED_ALGORITHM`, `ANO_CRYPTO_ERR_UNSUPPORTED_PARAMETER`, `ANO_CRYPTO_ERR_NOT_IMPLEMENTED` | `unsupported` |
| `ANO_CRYPTO_ERR_NOT_APPROVED_IN_MODE` | `not_approved` |
| `ANO_CRYPTO_ERR_NOT_INITIALIZED`, `ANO_CRYPTO_ERR_FATAL_STATE` | `not_operational` |
| `ANO_CRYPTO_ERR_ENTROPY_SOURCE_FAILED` | `entropy_failure` |
| `ANO_CRYPTO_ERR_DRBG_RESEED_REQUIRED` | `reseed_required` |
| `ANO_CRYPTO_ERR_AUTHENTICATION_FAILED` | `authentication_failed` |
| `ANO_CRYPTO_ERR_INTEGRITY_CHECK_FAILED` | `integrity_failure` |
| `ANO_CRYPTO_ERR_RESOURCE_EXHAUSTED` | `resource_exhausted` |
| `ANO_CRYPTO_ERR_INTERNAL_ERROR` or unknown | `internal_error` |

`ANO_CRYPTO_ERR_SELF_TEST_FAILED` remains a lifecycle `self_test_failed` result
and places the module in non-operational error state.

The production adapter implements lifecycle conversion separately from the
future cryptographic service-operation conversion. Unknown native states map
to Enterprise `error`; unknown lifecycle statuses map to `internal_error`.

## Capability status

Ready for native adapter integration:

- module lifecycle and self-test reporting;
- version and build identity;
- SHA-256 and HMAC-SHA-256;
- HMAC_DRBG-SHA-256 and platform-backed random.

Additional implemented AnoCrypto-C services are SHA-384/SHA-512, matching HMAC
variants, AES-128/192/256-CBC, AES-CMAC, and in-memory key handles. They are not
added to the current Enterprise provider capability mask because they do not
replace missing product requirements.

Full Enterprise parity remains blocked by missing HKDF-SHA-256, scrypt,
AES-256-GCM, streaming AEAD, and key wrapping. Missing services never fall back
to OpenSSL and are never advertised as available.

## Packaging, platforms, and licensing

AnoCrypto-C has shared-package evidence for Linux and Windows. Source branches
exist for Linux, Windows, and Apple platform entropy and synchronization.
Static package consumption remains unverified. Windows and macOS hosted
verification is deferred, as are hosted artifact and provenance checks.

Linux native verification inspects both the lifecycle executable and imported
AnoCrypto-C library with `ldd`, rejecting `libcrypto` or `libssl`. Windows and
macOS dependency inspection remains deferred until a suitable local or hosted
package is available.

AnoCrypto-C remains MPL-2.0. Enterprise does not relicense it. Applicable MPL
source and notice obligations must be preserved; private-repository or
commercial status does not remove them. Legal review is required before
customer delivery. This document is an engineering record, not legal advice.

No public forced-KAT-failure hook is approved, so native self-test-failure
injection remains deferred. Existing mock self-test-failure tests remain the
only failure-path evidence.

The proprietary lifecycle adapter is linked into the build-tree AnoCrypto-C
profile and reports no cryptographic capability bits. Its source/header are not
installed or exported, and the profile remains excluded from CPack, customer
archives, and the delivery SBOM. Lifecycle readiness therefore does not make
the complete profile ready. The AnoCrypto-C production profile remains blocked
from customer delivery.
