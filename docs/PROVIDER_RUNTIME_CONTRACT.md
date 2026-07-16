# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Enterprise Provider Runtime Contract

The Enterprise provider runtime contract is the link-time boundary between the
Enterprise product layer and a compile-time-selected backend lifecycle adapter.
It is separate from the Community cryptographic provider contract.

## Contract header

Adapters include:

```cpp
#include "anosecurekit_enterprise/detail/provider_runtime_contract.hpp"
```

and define exactly one symbol:

```cpp
const anosecurekit_enterprise::detail::provider_runtime_api&
anosecurekit_enterprise::detail::selected_provider_runtime() noexcept;
```

Contract version `1` supplies:

- initialize;
- shutdown;
- runtime snapshot.

The snapshot reports:

- backend/module name;
- module version;
- build identity;
- runtime status;
- module state;
- self-test status;
- runtime capability mask.

Module states have stable names: `unavailable`, `uninitialized`,
`self-test-running`, `operational`, `error`, and `shutdown`. The AnoCrypto-C
adapter must map all five native module states without collapsing shutdown into
uninitialized.

This is compile-time/link-time selection. Runtime plugin discovery, dynamic
provider loading, and automatic backend fallback are not supported.

## CMake target contract

The AnoCrypto-C profile builds the proprietary adapter as a non-imported
`OBJECT_LIBRARY` with backend identity `anocrypto-c`, runtime contract version
`1`, and a direct `AnoCryptoC::AnoCryptoC` link. Production builds use this
built-in target. `ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET` remains
only as a test fixture override for mock runtime-contract coverage:

```text
ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET
```

The target must set:

```cmake
set_property(TARGET <runtime> PROPERTY
  ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID "anocrypto-c")
set_property(TARGET <runtime> PROPERTY
  ANOSECUREKIT_ENTERPRISE_RUNTIME_CONTRACT_VERSION "1")
target_link_libraries(<runtime> PRIVATE AnoCryptoC::AnoCryptoC)
```

Configuration fails for an invalid override target, imported target, wrong
target type, wrong backend identity, wrong contract version, or missing direct
module link.

## Readiness rules

A profile is ready only when all of the following hold:

- runtime status is `ready`;
- module state is `operational`;
- the runtime capability mask contains the complete required product surface;
- for AnoCrypto-C, self-test status is `passed`;
- for OpenSSL, self-test status may be `not-applicable` or `passed`.

Initialization failure, self-test failure, non-operational state, an invalid
function table, or missing runtime capabilities fails closed.

## Current implementation boundary

The OpenSSL profile has a built-in runtime implementation reporting the verified
Community v0.4.0 provider baseline.

The test suite builds mock AnoCrypto-C runtime adapters for:

- ready/operational/self-test-passed;
- self-test failure;
- invalid runtime contract version.

The proprietary production adapter calls the installed `AnoCryptoC::AnoCryptoC`
package through the public lifecycle and identity headers recorded in
[ANOCRYPTO_C_PINNED_CONTRACT.md](ANOCRYPTO_C_PINNED_CONTRACT.md). It verifies
native initialization, startup self-test, operational gating, pinned identity,
idempotent lifecycle behavior, and shutdown/reinitialization. Error state and
fatal status consult the native last-error query.

The opt-in harness compiles that production source into a standalone test
executable and compares its native identity query with the Enterprise snapshot.
The adapter reports capability mask `0`; `backend_profile_ready()` therefore
remains false despite lifecycle readiness. The build-tree AnoCrypto-C profile,
adapter headers, and adapter objects remain excluded from installation, exports,
customer archives, and the delivered SBOM.

## Operation status contract

Lifecycle readiness and cryptographic operation results are separate. Public
`backend_operation_status` values preserve `success`, invalid argument, buffer
too small, unsupported, not approved, not operational, entropy failure, reseed
required, authentication failure, integrity failure, resource exhaustion, and
internal error. Unknown values render as `unknown`.

The production adapter converts native lifecycle results to
`backend_runtime_status`, preserving self-test failure, integrity/startup
failure, not-operational/fatal state, internal error, and unknown fail-closed
behavior. This conversion is lifecycle-only. Future cryptographic service
failures must use a separate `backend_operation_status` conversion and must not
be collapsed into `backend_runtime_status`.

## Required adapter behavior

The AnoCrypto-C lifecycle adapter:

1. initialize the module idempotently;
2. run or verify startup self-tests;
3. expose the module's sticky error/non-operational state;
4. provide stable module version and build identity strings;
5. map native lifecycle statuses without hiding failures;
6. report only capabilities confirmed by the active module build;
7. make shutdown safe and idempotent;
8. never route failures or missing services to OpenSSL.

AnoCrypto-C currently exposes no approved public forced-KAT-failure hook.
Native failure injection is deferred; mock self-test-failure coverage remains.

This contract and its tests are engineering controls, not KCMVP or FIPS
validation evidence.
