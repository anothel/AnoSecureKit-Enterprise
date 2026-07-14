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

This is compile-time/link-time selection. Runtime plugin discovery, dynamic
provider loading, and automatic backend fallback are not supported.

## CMake target contract

The AnoCrypto-C profile requires a non-imported `OBJECT_LIBRARY` named by:

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

Configuration fails for a missing target, imported target, wrong target type,
wrong backend identity, wrong contract version, or missing direct module link.

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

The production AnoCrypto-C lifecycle adapter is intentionally not implemented
from guessed function signatures. It must be completed against a pinned external
AnoCrypto-C package and its exact public headers.

## Required adapter behavior

The eventual AnoCrypto-C adapter must:

1. initialize the module idempotently;
2. run or verify startup self-tests;
3. expose the module's sticky error/non-operational state;
4. provide stable module version and build identity strings;
5. map native statuses to Enterprise runtime statuses without hiding failures;
6. report only capabilities confirmed by the active module build;
7. make shutdown safe and idempotent;
8. never route failures or missing services to OpenSSL.

This contract and its tests are engineering controls, not KCMVP or FIPS
validation evidence.
