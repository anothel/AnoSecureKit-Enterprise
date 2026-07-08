# AnoSecureKit Enterprise

AnoSecureKit Enterprise is the private/commercial distribution layer for the
AnoSecureKit product family.

This scaffold contains:

- a vendored AnoSecureKit Community source tree under `third_party/anosecurekit-community`;
- an Enterprise wrapper target, `anosecurekit_enterprise`;
- product-boundary, packaging, and KCMVP-preparation documents;
- a placeholder location for the private AnoCrypto Core module.

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

When the private AnoCrypto Core repository/package exists, supply it through one
of these approaches:

1. private package: `find_package(anocrypto CONFIG REQUIRED)`;
2. private subtree/submodule: `third_party/anocrypto/CMakeLists.txt`;
3. internal build system package feed.

Then configure:

```sh
cmake -S . -B build-enterprise   -DANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO=ON   -DANOCRYPTO_ROOT=/path/to/anocrypto
```

Do not document AnoCrypto as available to customers until the backend passes the
compatibility, security, licensing, and release evidence gates in `docs/`.
