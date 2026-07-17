# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Enterprise CI and Release Gate

AnoSecureKit Enterprise uses a private CI gate for the OpenSSL profile. The gate
verifies source builds, installed package consumption, internal-delivery archives,
license/source-offer obligations, checksums, and SPDX metadata. It does not publish
or sign a customer release.

## Aggregate local gate

Configure a bundled Community OpenSSL profile with tests enabled, then run:

```sh
cmake --build build --config Release --target enterprise-release-preflight --parallel 4
```

The aggregate target requires:

- Enterprise profile and runtime-contract checks;
- OpenSSL support-policy diagnostics and Enterprise/OpenSSL source-boundary checks;
- the non-package CTest inventory, with install and delivery package gates executed separately;
- installed CMake package and consumer verification;
- CPack ZIP/TGZ delivery generation;
- Community v0.4.0 source-offer verification;
- staged and archived SHA-256 manifest validation;
- SPDX 2.3 delivery SBOM validation;
- CI workflow policy validation;
- external release-evidence verifier capability and fail-closed contract tests;
- release-authorization schema, default-deny, positive test-only fixture, and
  fail-closed negative validation.

`ANOSECUREKIT_ENTERPRISE_TEST_PARALLEL_LEVEL` controls CTest concurrency and must
be a positive integer.

The aggregate preflight validates the authorization contract but remains an
internal qualification gate. It does not grant customer release. After creating
the internal artifact set, the strict customer gates are:

```sh
cmake --build build --target enterprise-release-authorization-check
cmake --build build --target enterprise-customer-delivery-check
```

Both fail with the repository's default deny record. See
[RELEASE_AUTHORIZATION_POLICY.md](RELEASE_AUTHORIZATION_POLICY.md). Production
allow requires hosted evidence plus successful external cryptographic and
trusted-evidence verification.

## Opt-in AnoCrypto-C lifecycle, SHA-256, HMAC-SHA-256, and random gate

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
  --target enterprise-native-anocrypto-c-sha256-check \
    enterprise-native-anocrypto-c-hmac-sha256-check \
    enterprise-native-anocrypto-c-random-check --parallel 4
```

A package reporting commit `unknown` fails by default. For development-only
lifecycle testing, add:

```sh
-DANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_FOR_TESTS=ON
```

The override does not approve package provenance. In the `anocrypto-c`
development profile, the focused targets run lifecycle gating, public SHA-256,
HMAC-SHA-256, and random contracts, native negative cases, and dependency
inspection. Random covers 0/1/65,535/65,536/65,537 bytes, multiple chunks, a
fixed large size, key/token helpers, pre-init/post-shutdown rejection, mock
unavailable/status failures, context cleanup, and whole-output clearing. An
OpenSSL build may still enable the option for standalone lifecycle/status
checks. With the option `OFF`, configuration and normal OpenSSL gates do not
discover or require AnoCrypto-C.

Linux uses `ldd` to reject `libcrypto` or `libssl` dependencies in the lifecycle,
SHA-256, HMAC-SHA-256, and random executables and imported AnoCrypto-C library.
Windows/macOS inspection remains deferred. Native self-test-failure injection
remains deferred pending an approved upstream public hook.

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

After artifact validation, `main`/release-tag pushes and explicit dispatches use
the pinned official `actions/attest` action to attest an exact checksum list.
A following job verifies every downloaded subject with the same installed
`check_release_evidence_verifier.cmake` adapter. Pull requests do not receive
attestation permissions. Until a hosted run completes both jobs, cryptographic
and trusted evidence remain unavailable and customer release remains denied.

## Current release policy

The workflow has global read-only repository permissions and contains no
release-upload step. Only the post-validation attestation job receives scoped
OIDC and attestation write permissions. Publisher authentication, support
approval, and legal approval remain separate gates. The incomplete AnoCrypto-C
profile cannot install or produce delivery artifacts. Native lifecycle,
SHA-256, HMAC-SHA-256, and random success do not change its full required capability mask,
approved-digest block, install/export state, or customer-delivery status.

When hosted execution is unavailable, [DEFERRED_CI_STATUS.md](DEFERRED_CI_STATUS.md)
records local evidence, deferred remote checks, and the customer-release block.
