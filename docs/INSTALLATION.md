# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Enterprise OpenSSL Profile Installation

AnoSecureKit Enterprise currently exposes an installable CMake package only for
the verified OpenSSL delivery profile. The incomplete AnoCrypto-C profile is a
build-tree integration path and intentionally produces no install/export or
customer package.

## Build and install

```sh
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl
cmake --build build --config Release --parallel
cmake --install build --config Release --prefix /path/to/prefix
```

A bundled OpenSSL-profile install contains both packages:

```text
find_package(anosecurekit 0.4 CONFIG REQUIRED)
find_package(anosecurekitEnterprise 0.1 CONFIG REQUIRED)

target_link_libraries(app PRIVATE anosecurekit::enterprise)
```

The Enterprise config loads the Community package first and exports the target:

```text
anosecurekit::enterprise
```

The package records:

```text
ANOSECUREKIT_ENTERPRISE_PACKAGE_VERSION
ANOSECUREKIT_ENTERPRISE_PACKAGE_BACKEND_PROFILE
```

The installed public headers are limited to `enterprise.hpp` and
`provider_runtime.hpp`. The private provider runtime contract under `detail/`
is not part of the customer API or installed package.

## Verification

With tests enabled, run:

```sh
cmake --build build --target enterprise-package-check
```

The check stages an install, verifies licenses/notices and both CMake package
configs, configures an independent consumer with `find_package()`, links
`anosecurekit::enterprise`, executes SHA-256 through the Community surface, and
checks Enterprise runtime/profile information.

## AnoCrypto-C profile restriction

The AnoCrypto-C profile is not installable until all of the following are true:

- a pinned `AnoCryptoC::AnoCryptoC` package is supplied;
- the proprietary provider supplies every required capability and the pinned
  runtime adapter passes all gates;
- the complete capability contract is satisfied;
- Community API/format parity and no-OpenSSL linkage gates pass;
- customer delivery, license, security, and validation claims are reviewed.

A build-tree partial or metadata-only adapter is never a customer-delivery package.

## Customer delivery archive gate

For the bundled OpenSSL profile, run:

```sh
cmake --build build --target enterprise-delivery-check
```

The output directory contains CPack ZIP/TGZ install archives, a Community
source-offer ZIP, delivery metadata, an SPDX 2.3 SBOM, and `SHA256SUMS.txt`. See
`docs/DELIVERY_VERIFICATION.md` for the verification contract.


## Release preflight

For the bundled OpenSSL profile, run the complete local release gate with:

```sh
cmake --build build --config Release --target enterprise-release-preflight --parallel 4
```

CTest parallelism is controlled by the positive integer cache variable
`ANOSECUREKIT_ENTERPRISE_TEST_PARALLEL_LEVEL`.
