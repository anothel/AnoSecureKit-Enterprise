# AnoCrypto-C Integration Plan

AnoCrypto-C is an external C99 module managed in its own repository. Enterprise
integrates it through a proprietary C++ provider adapter; the module itself is
not copied into this repository.

## Package contract

```cmake
find_package(AnoCryptoC CONFIG REQUIRED)
target_link_libraries(provider PRIVATE AnoCryptoC::AnoCryptoC)
```

## First gate now implemented

- explicit `openssl` and `anocrypto-c` profile selection;
- exact `AnoCryptoC::AnoCryptoC` target requirement;
- non-imported `OBJECT_LIBRARY` adapter requirement;
- configure-time failure when the package or adapter is absent;
- no silent OpenSSL fallback.

## Remaining implementation

1. Implement the proprietary provider adapter.
2. Integrate module initialization, self-test, and operational-state checks.
3. Map status/error codes.
4. Map SHA-256, HMAC-SHA-256, and random first.
5. Fail closed for missing HKDF, AEAD, streaming, key-wrap, and password-KDF
   capabilities until AnoCrypto-C supplies them.
6. Run the Community API/fixture suite through the profile.
7. Verify the final AnoCrypto-C product has no OpenSSL production linkage.
