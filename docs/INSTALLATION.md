# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Enterprise OpenSSL Profile Installation

AnoSecureKit Enterprise currently exposes an installable CMake package only for
the verified OpenSSL delivery profile. The P3-06 AnoCrypto-C profile is a
build-tree engineering-parity path and intentionally produces no install/export
or customer package.

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

P3-06 completes the current primitive and Community-format parity checkpoint,
but the AnoCrypto-C profile remains non-installable. CMake install rules,
package exports and delivery/CPack targets are not produced for this profile.

This restriction remains until all of the following are true:

- the exact dependency provenance and package digest are approved;
- the proprietary adapter and complete capability contract pass all gates;
- Community API/format parity and cross-platform no-OpenSSL linkage gates pass;
- hosted platform qualification and review complete;
- trusted signing and attestation evidence is verified;
- legal, security and support transition is approved;
- external customer release is explicitly authorized.

A successful build-tree parity test is never a customer-delivery package.

The reintegration validation used AnoCrypto-C development revision
`c101c9655f881044c14d8efbc20ea94a2e84f30b` for compatibility only. Its Linux
installed-package smoke test fails because its exported CMake target references
`Threads::Threads` without loading that dependency. This repository does not
work around that package defect in production configuration.

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
