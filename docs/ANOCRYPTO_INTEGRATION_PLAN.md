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
- built-in proprietary production lifecycle adapter;
- runtime contract version and backend identity validation;
- direct `AnoCryptoC::AnoCryptoC` linkage for both adapters;
- fail-closed runtime status, module state, self-test, and capability checks;
- opt-in installed-package lifecycle tests with explicit runtime/commit pins;
- production native state/lifecycle mapping and Linux dependency-purity checks;
- exhaustive service-operation status mapping with unknown-value fail-closed
  coverage;
- public SHA-256 through `ano_crypto_hash_digest` with OpenSSL parity and native
  negative tests;
- no silent OpenSSL fallback.

## Current runtime boundary

Enterprise defines runtime contract version `1` for initialization, shutdown,
module/self-test state, module version/build identity, status mapping, and
runtime capability reporting. The OpenSSL profile supplies a built-in
implementation. Mock AnoCrypto-C adapters verify ready, self-test-failed, and
invalid-contract behavior.

The exact native public headers and lifecycle symbols are verified and pinned.
The production adapter calls them directly, verifies runtime/build identity at
initialization, and reports module/self-test state through runtime contract
version `1`. The opt-in harness compiles the same adapter and verifies the real
lifecycle sequence. The runtime capability mask now contains only `sha256`, so
lifecycle readiness still does not make the complete profile ready.

A separate production helper maps every defined AnoCrypto-C service status to
the stable Enterprise operation-status contract. The SHA-256 provider uses that
mapper for `ano_crypto_hash_digest`; unknown values map to `internal_error`.
All unconnected backend functions fail closed without OpenSSL fallback.

## Remaining implementation

1. Approve and record the package/archive digest.
2. Verify static package consumption.
3. Map HMAC-SHA-256 and platform-backed random using confirmed APIs.
4. Fail closed for missing HKDF, AEAD, streaming, key-wrap, and password-KDF
   capabilities until AnoCrypto-C supplies them.
5. Run the Community API/fixture suite through the profile.
6. Add native self-test-failure evidence only after an upstream public test hook
   is approved.
7. Verify Windows/macOS package dependency purity and hosted execution.

## Adapter readiness sequence

1. Discover `AnoCryptoC` and require `AnoCryptoC::AnoCryptoC`.
2. Build the proprietary cryptographic provider adapter.
3. Build the proprietary runtime/lifecycle adapter.
4. Build and verify the separate native operation-status mapper.
5. Build and verify the native SHA-256 adapter and cross-backend vectors.
6. Validate CMake identity, contract version, direct module linkage, and static
   capabilities.
7. Initialize the actual module and verify self-test/operational state.
8. Compare runtime capabilities against the complete product requirement.
9. Only then enable full API parity tests and production packaging.

The verified AnoCrypto-C feature set is not sufficient for the full production
gate because HMAC-SHA-256, HKDF-SHA-256, random, scrypt, AES-256-GCM, streaming
AEAD, and key wrapping are absent from the Enterprise adapter. The approved
package digest is also unresolved. Passing native lifecycle and SHA-256 targets
does not enable installation, customer packaging, fallback, or production
profile readiness.
