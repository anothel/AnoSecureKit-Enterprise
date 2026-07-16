# AnoCrypto-C Integration Plan

AnoCrypto-C is an external C99 module managed in its own repository. Enterprise
integrates it through proprietary C++ provider adapters; the module itself is
not copied into this repository.

## Package contract

```cmake
find_package(AnoCryptoC 0.1.0 EXACT CONFIG REQUIRED)
target_link_libraries(provider PRIVATE AnoCryptoC::AnoCryptoC)
```

The verified baseline is commit
`cf0f3c425dd265c7509fb64a6123db97f71055dd`, runtime identity
`0.1.0-p1-33-release-rehearsal`, build identity ABI `1`, and 69 public symbols.
Version matching alone is insufficient; package digest and runtime identity
verification are mandatory. See
[ANOCRYPTO_C_PINNED_CONTRACT.md](ANOCRYPTO_C_PINNED_CONTRACT.md).

## Implemented gates

- explicit `openssl` and `anocrypto-c` profile selection;
- exact `AnoCryptoC::AnoCryptoC` target requirement;
- non-imported cryptographic provider `OBJECT_LIBRARY` requirement;
- complete static production capability declaration;
- separate non-imported lifecycle/diagnostic `OBJECT_LIBRARY` requirement;
- runtime contract version and backend identity validation;
- direct `AnoCryptoC::AnoCryptoC` linkage for both adapters;
- fail-closed runtime status, module state, self-test, and capability checks;
- opt-in installed-package lifecycle tests with explicit runtime/commit pins;
- test-only native state/lifecycle mapping and Linux dependency-purity checks;
- no silent OpenSSL fallback.

## Current runtime boundary

Enterprise defines runtime contract version `1` for initialization, shutdown,
module/self-test state, module version/build identity, status mapping, and
runtime capability reporting. The OpenSSL profile supplies a built-in
implementation. Mock AnoCrypto-C adapters verify ready, self-test-failed, and
invalid-contract behavior.

The exact native public headers and lifecycle symbols are verified and pinned.
When explicitly enabled, a test-owned adapter calls the installed package and
verifies the real lifecycle sequence. Its capability mask is zero and its
`lifecycle ready` assertion covers only runtime status, operational state, and
self-test success. It is not the production profile and does not advertise
cryptographic service parity.

## Remaining implementation

1. Approve and record the package/archive digest.
2. Verify static package consumption.
3. Implement the production lifecycle/runtime adapter after delivery provenance
   is approved.
4. Implement a separate service-operation status conversion.
5. Map SHA-256, HMAC-SHA-256, and platform-backed random using confirmed APIs.
6. Fail closed for missing HKDF, AEAD, streaming, key-wrap, and password-KDF
   capabilities until AnoCrypto-C supplies them.
7. Run the Community API/fixture suite through the profile.
8. Add native self-test-failure evidence only after an upstream public test hook
   is approved.
9. Verify Windows/macOS package dependency purity and hosted execution.

## Adapter readiness sequence

1. Discover `AnoCryptoC` and require `AnoCryptoC::AnoCryptoC`.
2. Build the proprietary cryptographic provider adapter.
3. Build the proprietary runtime/lifecycle adapter.
4. Validate CMake identity, contract version, direct module linkage, and static
   capabilities.
5. Initialize the actual module and verify self-test/operational state.
6. Compare runtime capabilities against the complete product requirement.
7. Only then enable public API parity tests and production packaging.

The verified AnoCrypto-C feature set is not sufficient for the full production
gate because HKDF-SHA-256, scrypt, AES-256-GCM, streaming AEAD, and key wrapping
are absent. The approved package digest is also unresolved. Passing the native
lifecycle target does not enable installation, customer packaging, fallback,
or production profile readiness.
