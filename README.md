# AnoSecureKit Enterprise

AnoSecureKit Enterprise is the private/proprietary product layer for the
AnoSecureKit family. It is intended to cover the AnoSecureKit Community
functionality while adding Enterprise policy, diagnostics, packaging,
deployment, and customer-delivery support.

## Current Status

This repository is an internal `0.1.0` scaffold, not a sellable product.

It currently contains:

- the verified AnoSecureKit Community `v0.3.0` source under
  `third_party/anosecurekit-community`;
- an Enterprise wrapper target, `anosecurekit_enterprise`;
- an information executable;
- product-boundary, packaging, and KCMVP-preparation documents;
- delivery-directory manifest generation and verification tooling.

The current runnable target links Community's final OpenSSL-backed target. It is
therefore an OpenSSL-based scaffold. A production AnoCrypto-C profile is not yet
implemented.

It intentionally does **not** contain AnoCrypto-C source code or package
contents, license activation, customer contracts, or a KCMVP/FIPS-validated
cryptographic module.

## Product Profiles

The intended explicit profiles are:

```text
Enterprise OpenSSL profile
= Community functionality + OpenSSL provider + Enterprise layer

Enterprise AnoCrypto-C profile
= Community functionality + proprietary AnoCrypto-C provider
  + external AnoCryptoC::AnoCryptoC + Enterprise layer
```

See [docs/BACKEND_PROFILES.md](docs/BACKEND_PROFILES.md) for the current truth,
target architecture, capability gate, no-fallback rule, and test requirements.

## Build the Current Scaffold

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target anosecurekit_enterprise anosecurekit_enterprise_info
./build/anosecurekit_enterprise_info
```

The scaffold uses the bundled Community source and disables Community tests/CLI
by default so it can build as an Enterprise library layer.

## AnoCrypto-C Integration Status

AnoCrypto-C is managed outside this repository. The recorded external package
contract is:

```cmake
find_package(AnoCryptoC CONFIG REQUIRED)
target_link_libraries(<private-adapter> PRIVATE AnoCryptoC::AnoCryptoC)
```

The current `ANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO` option and generic
`anocrypto` target lookup are legacy scaffold code. They do not replace the
Community OpenSSL provider and must not be treated as a working profile.

Do not enable or advertise an AnoCrypto-C product profile until the Community
provider seam, proprietary adapter, module lifecycle/self-test gate, capability
checks, no-OpenSSL-linkage check, and profile packaging tests exist.

## Documentation

- [Product boundary](docs/PRODUCT_BOUNDARY.md)
- [Backend profiles](docs/BACKEND_PROFILES.md)
- [AnoCrypto-C integration plan](docs/ANOCRYPTO_INTEGRATION_PLAN.md)
- [Community dependency provenance](docs/COMMUNITY_DEPENDENCY.md)
- [Customer delivery pack](docs/CUSTOMER_DELIVERY_PACK.md)
- [KCMVP preparation checklist](docs/KCMVP_PREPARATION_CHECKLIST.md)

## Licensing

Enterprise-owned files are proprietary commercial software. See [LICENSE](LICENSE)
for the canonical repository notice and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
for bundled and external dependency boundaries.
