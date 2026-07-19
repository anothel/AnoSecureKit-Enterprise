# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Enterprise CI and Release Gate

AnoSecureKit Enterprise uses a private CI gate for the OpenSSL profile. The gate
verifies source builds, installed package consumption, internal-delivery archives,
license/source-offer obligations, checksums, and SPDX metadata. It does not publish
or sign a customer release.

## OpenSSL aggregate local gate

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
- support lifecycle, vulnerability response, ownership, and release-revocation
  policy validation;
- the authoritative pre-GA blocker registry, development-freeze contract, exact
  revision binding, queue routing, and false-closure negative cases;
- test-only incident/revocation scenarios, ownership routing, state transitions,
  fail-closed decisions, and negative contract validation;
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

The registry-only gate is also available as
`enterprise-pre-ga-blocker-registry-check`. Its OpenSSL scope does not require
the separate AnoCrypto-C profile to reach GA.

## AnoCrypto-C P3-06 parity gate

Configure with the exact P3-05 package:

```sh
cmake -S . -B build-native -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=anocrypto-c \
  -DANOSECUREKIT_ENTERPRISE_ENABLE_NATIVE_ANOCRYPTO_C_TESTS=ON \
  -DANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID=0.1.0-p3-05-scrypt-fixed-profile \
  -DANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT=89e16a261ab7696d9489167d7403d9f2c704629e \
  -DAnoCryptoC_DIR=<prefix>/lib/cmake/AnoCryptoC
cmake --build build-native --target enterprise-anocrypto-c-parity-check
```

The gate covers:

- lifecycle, identity, self-test and status mapping;
- all seven required capabilities;
- exact `SKT1`, `SKF1` and `SKP1` fixtures;
- packet/file/password/key-wrap round trips;
- wrong-key authentication and no-output behavior;
- source/package boundary checks;
- Linux `ldd` rejection of `libcrypto` and `libssl`.

P3-06 is engineering parity only. The AnoCrypto-C profile remains non-installable,
has no CPack/customer-delivery path, and cannot fall back to OpenSSL. With native
tests disabled, configuration does not enable test-only lifecycle seams.

## GitHub Actions matrix

The private workflow covers:

- Linux GCC Release static;
- Linux Clang Release static;
- Linux GCC Release shared;
- Windows MSVC Release shared;
- macOS AppleClang Release static;
- Linux Clang Debug with AddressSanitizer and UndefinedBehaviorSanitizer through
  the runtime-only `enterprise-sanitizer-check`;
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

## Current external state

- hosted lanes: `NOT_RUN`;
- hosted review: `UNREVIEWED`;
- repository/production signing: `UNSIGNED`;
- signing handoff: `BLOCKED`;
- external release authorization: `NO`;
- KCMVP work: `DEFERRED`.

The workflow has global read-only repository permissions and contains no
release-upload step. Only the post-validation attestation job receives scoped
OIDC and attestation write permissions. Publisher authentication, support
approval, legal approval, hosted qualification, and OpenSSL GA blockers remain
separate gates. P3-06 does not change these states. Windows and macOS runtime
dependency inspection is `EXTERNAL_CONFIRMATION_REQUIRED` until hosted lanes run.

When hosted execution is unavailable, [DEFERRED_CI_STATUS.md](DEFERRED_CI_STATUS.md)
records local evidence, deferred remote checks, and the customer-release block.
