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
[docs/ANOCRYPTO_INTEGRATION_PLAN.md](docs/ANOCRYPTO_INTEGRATION_PLAN.md). The
verified external dependency identity, headers, lifecycle, status, licensing,
and capability gaps are pinned in
[docs/ANOCRYPTO_C_PINNED_CONTRACT.md](docs/ANOCRYPTO_C_PINNED_CONTRACT.md).


## Installable OpenSSL profile package

The verified OpenSSL delivery profile installs both the Community v0.4.0 CMake
package and the Enterprise package into one prefix:

```sh
cmake --install build --config Release --prefix /path/to/prefix
```

Consumers use:

```cmake
find_package(anosecurekit 0.4 CONFIG REQUIRED)
find_package(anosecurekitEnterprise 0.1 CONFIG REQUIRED)
target_link_libraries(app PRIVATE anosecurekit::enterprise)
```

Run `enterprise-package-check` to stage an install and build an independent
consumer. The incomplete AnoCrypto-C profile intentionally exports and installs
nothing. See [docs/INSTALLATION.md](docs/INSTALLATION.md).


## Customer delivery archives

The bundled OpenSSL profile can stage verified customer-delivery assets with:

```sh
cmake --build build --target enterprise-delivery-check
```

The gate creates CPack ZIP/TGZ install archives, a separate MPL-2.0 Community
source-offer archive, SPDX 2.3 delivery SBOM, build metadata, and
`SHA256SUMS.txt`, then extracts and verifies the archives. The incomplete
AnoCrypto-C profile remains non-installable and cannot produce delivery assets.
See [docs/DELIVERY_VERIFICATION.md](docs/DELIVERY_VERIFICATION.md).

## Licensing

Enterprise-owned files are proprietary commercial software. Community files
remain MPL-2.0. AnoCrypto-C is external MPL-2.0 software and is not relicensed
by Enterprise. Applicable source and notice obligations remain subject to legal
review before delivery. See
[LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## AnoCrypto-C provider capability contract

The `anocrypto-c` profile remains fail-closed. A proprietary provider `OBJECT_LIBRARY` must declare:

- `ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID=anocrypto-c`;
- `ANOSECUREKIT_ENTERPRISE_PROVIDER_CAPABILITIES` containing `sha256`, `hmac-sha256`, `hkdf-sha256`, `random`, `scrypt`, `aes256-gcm`, and `aes256-gcm-stream`;
- a direct link to `AnoCryptoC::AnoCryptoC`.

The profile does not configure when any required capability is missing. Partial AnoCrypto-C support is not silently completed with OpenSSL.

See [docs/PROVIDER_CAPABILITY_CONTRACT.md](docs/PROVIDER_CAPABILITY_CONTRACT.md) for the target metadata and runtime-gate requirements.

## Provider lifecycle and diagnostics contract

Enterprise now exposes a compile-time-selected runtime contract for backend
initialization, shutdown, self-test state, module state, module/build identity,
and runtime capability reporting.

The OpenSSL profile supplies the built-in baseline implementation. The
AnoCrypto-C profile additionally requires a separate non-imported
`OBJECT_LIBRARY` selected through:

```text
ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET
```

That target must declare:

```cmake
ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID=anocrypto-c
ANOSECUREKIT_ENTERPRISE_RUNTIME_CONTRACT_VERSION=1
```

and link `AnoCryptoC::AnoCryptoC` directly. The runtime API is a link-time
contract, not a runtime plugin system. A wrong contract version, failed
self-test, non-operational module state, or incomplete runtime capability mask
keeps the profile unavailable.

The current repository validates this boundary with mock adapters. Exact native
headers and symbols are pinned, but no concrete AnoCrypto-C function is called
yet. See [docs/PROVIDER_RUNTIME_CONTRACT.md](docs/PROVIDER_RUNTIME_CONTRACT.md).


## CI and release gate

See `docs/CI_AND_RELEASE_GATE.md`.
