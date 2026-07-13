# AnoSecureKit Enterprise

AnoSecureKit Enterprise is the private/commercial superset of AnoSecureKit
Community. It uses Community v0.4.0 as the common C++ API and implementation
baseline and selects one explicit cryptographic backend profile.

## Profiles

### OpenSSL

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
  -DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl
cmake --build build --target anosecurekit_enterprise anosecurekit_enterprise_info
ctest --test-dir build --output-on-failure
```

This working profile provides the Community feature set through OpenSSL and adds
the Enterprise product layer.

### AnoCrypto-C

```sh
-DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=anocrypto-c
```

The AnoCrypto-C profile requires the external package target
`AnoCryptoC::AnoCryptoC` and a complete proprietary Enterprise provider adapter.
It is fail-closed and never silently uses OpenSSL for missing operations. The
adapter is not yet complete, so this profile is not currently production-ready.

See [docs/BACKEND_PROFILES.md](docs/BACKEND_PROFILES.md) and
[docs/ANOCRYPTO_INTEGRATION_PLAN.md](docs/ANOCRYPTO_INTEGRATION_PLAN.md).

## Licensing

Enterprise-owned files are proprietary commercial software. Community files
remain MPL-2.0. AnoCrypto-C is external and separately licensed. See
[LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
