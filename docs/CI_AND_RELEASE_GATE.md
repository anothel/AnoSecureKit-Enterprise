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

## Opt-in AnoCrypto-C lifecycle and SHA-256 gate

The installed-package harness compiles the production lifecycle adapter and is
disabled by default. Enable it only with an external exact-version package and
explicit development test pins:

```sh
cmake -S . -B build-native -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=anocrypto-c \
  -DANOSECUREKIT_ENTERPRISE_ENABLE_NATIVE_ANOCRYPTO_C_TESTS=ON \
  -DANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID=0.1.0-p1-33-release-rehearsal \
  -DANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT=cf0f3c425dd265c7509fb64a6123db97f71055dd \
  -DAnoCryptoC_DIR=<installed-prefix>/lib/cmake/AnoCryptoC
cmake --build build-native \
  --target enterprise-native-anocrypto-c-sha256-check --parallel 4
```

A package reporting commit `unknown` fails by default. For development-only
lifecycle testing, add:

```sh
-DANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_FOR_TESTS=ON
```

The override does not approve package provenance. In the `anocrypto-c`
development profile, the focused target runs lifecycle gating, the public
SHA-256 vectors and negative cases, and dependency inspection. An OpenSSL build
may still enable the option for standalone lifecycle/status checks. With the
option `OFF`, configuration and normal OpenSSL gates do not discover or require
AnoCrypto-C.

Linux uses `ldd` to reject `libcrypto` or `libssl` dependencies in the lifecycle
executable, SHA-256 executable, and imported AnoCrypto-C library. Windows/macOS
inspection remains deferred. Native self-test-failure injection remains
deferred pending an approved upstream public hook.

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
or produce delivery artifacts. Native lifecycle and SHA-256 success do not
change its full required capability mask, approved-digest block, install/export
state, or customer-delivery status.

When hosted execution is unavailable, [DEFERRED_CI_STATUS.md](DEFERRED_CI_STATUS.md)
records local evidence, deferred remote checks, and the customer-release block.
