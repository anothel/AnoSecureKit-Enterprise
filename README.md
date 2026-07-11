# AnoSecureKit Enterprise

AnoSecureKit Enterprise is the private/commercial distribution layer for the
AnoSecureKit product family.

This scaffold contains:

- a vendored AnoSecureKit Community source tree under `third_party/anosecurekit-community`;
- an Enterprise wrapper target, `anosecurekit_enterprise`;
- product-boundary, packaging, and KCMVP-preparation documents;
- a documented boundary for optional, externally supplied AnoCrypto integration.

It intentionally does **not** contain AnoCrypto source code, license activation,
customer contracts, or a KCMVP-validated cryptographic module.

## Build the scaffold

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target anosecurekit_enterprise anosecurekit_enterprise_info
./build/anosecurekit_enterprise_info
```

The scaffold uses the bundled Community source and disables Community tests/CLI
by default so it can build as an Enterprise library layer.

## Enable AnoCrypto integration later

When an AnoCrypto package exists, supply it externally through one of these
approaches:

1. private package: `find_package(anocrypto CONFIG REQUIRED)`;
2. source tree outside this repository through `ANOCRYPTO_ROOT`;
3. internal package feed.

Then configure:

```sh
cmake -S . -B build-enterprise   -DANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO=ON   -DANOCRYPTO_ROOT=/path/to/anocrypto
```

Do not document AnoCrypto as available to customers until the backend passes the
compatibility, security, licensing, and release evidence gates in `docs/`.

## Licensing

Enterprise-owned files are proprietary commercial software. See [LICENSE](LICENSE)
for the canonical repository notice and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
for bundled and external dependency boundaries.
