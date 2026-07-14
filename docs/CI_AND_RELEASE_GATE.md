# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Enterprise CI and Release Gate

AnoSecureKit Enterprise uses a private CI gate for the OpenSSL profile. The gate
verifies source builds, installed package consumption, customer-delivery archives,
license/source-offer obligations, checksums, and SPDX metadata. It does not publish
or sign a customer release.

## Aggregate local gate

Configure a bundled Community OpenSSL profile with tests enabled, then run:

```sh
cmake --build build --config Release --target enterprise-release-preflight --parallel 4
```

The aggregate target requires:

- Enterprise profile and runtime-contract checks;
- the non-package CTest inventory, with install and delivery package gates executed separately;
- installed CMake package and consumer verification;
- CPack ZIP/TGZ delivery generation;
- Community v0.4.0 source-offer verification;
- staged and archived SHA-256 manifest validation;
- SPDX 2.3 delivery SBOM validation;
- CI workflow policy validation.

`ANOSECUREKIT_ENTERPRISE_TEST_PARALLEL_LEVEL` controls CTest concurrency and must
be a positive integer.

## GitHub Actions matrix

The private workflow covers:

- Linux GCC Release static;
- Linux Clang Release static;
- Linux GCC Release shared;
- Windows MSVC Release shared;
- macOS AppleClang Release static;
- Linux Clang Debug with AddressSanitizer and UndefinedBehaviorSanitizer through the runtime-only `enterprise-sanitizer-check`;
- a non-bundled Community package consumer path.

Each platform build executes `enterprise-release-preflight` and uploads the verified
internal delivery directory for 14 days. Artifacts remain internal validation evidence;
they are not automatically published as GitHub Releases or approved customer packages.

## Current release policy

The workflow has read-only repository permissions and contains no release-upload step.
Publisher authentication, signing, provenance attestations, support approval, and legal
approval remain separate future gates. The incomplete AnoCrypto-C profile cannot install
or produce delivery artifacts.
