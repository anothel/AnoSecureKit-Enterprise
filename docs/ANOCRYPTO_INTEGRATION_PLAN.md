# AnoCrypto-C Integration Plan

AnoCrypto-C is an external C99 module managed in its own repository. Enterprise
integrates it through proprietary C++ provider adapters; the module itself is
not copied into this repository.

## Package contract

```cmake
find_package(AnoCryptoC CONFIG REQUIRED)
target_link_libraries(provider PRIVATE AnoCryptoC::AnoCryptoC)
```

## Implemented gates

- explicit `openssl` and `anocrypto-c` profile selection;
- exact `AnoCryptoC::AnoCryptoC` target requirement;
- non-imported cryptographic provider `OBJECT_LIBRARY` requirement;
- complete static production capability declaration;
- separate non-imported lifecycle/diagnostic `OBJECT_LIBRARY` requirement;
- runtime contract version and backend identity validation;
- direct `AnoCryptoC::AnoCryptoC` linkage for both adapters;
- fail-closed runtime status, module state, self-test, and capability checks;
- no silent OpenSSL fallback.

## Current runtime boundary

Enterprise defines runtime contract version `1` for initialization, shutdown,
module/self-test state, module version/build identity, status mapping, and
runtime capability reporting. The OpenSSL profile supplies a built-in
implementation. Mock AnoCrypto-C adapters verify ready, self-test-failed, and
invalid-contract behavior.

Concrete AnoCrypto-C lifecycle calls are not implemented from inferred function
signatures. The next integration change must use a pinned external package and
its exact installed headers.

## Remaining implementation

1. Pin the AnoCrypto-C package version and capture its installed public headers.
2. Implement the real lifecycle/runtime adapter against those exact APIs.
3. Map native status/error codes.
4. Map SHA-256, HMAC-SHA-256, and random using confirmed APIs.
5. Fail closed for missing HKDF, AEAD, streaming, key-wrap, and password-KDF
   capabilities until AnoCrypto-C supplies them.
6. Run the Community API/fixture suite through the profile.
7. Verify the final AnoCrypto-C product has no OpenSSL production linkage.

## Adapter readiness sequence

1. Discover `AnoCryptoC` and require `AnoCryptoC::AnoCryptoC`.
2. Build the proprietary cryptographic provider adapter.
3. Build the proprietary runtime/lifecycle adapter.
4. Validate CMake identity, contract version, direct module linkage, and static
   capabilities.
5. Initialize the actual module and verify self-test/operational state.
6. Compare runtime capabilities against the complete product requirement.
7. Only then enable public API parity tests and production packaging.

The current known AnoCrypto-C feature set is not sufficient for the full
production gate because HKDF, scrypt, AES-GCM, and streaming AEAD remain
unavailable or unconfirmed.
