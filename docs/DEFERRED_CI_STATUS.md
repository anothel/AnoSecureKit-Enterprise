# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Deferred CI Status

Status date: 2026-07-14

GitHub-hosted Actions execution is temporarily unavailable. Local verification
supports continued internal development but does not replace hosted
cross-platform, security-analysis, artifact, or provenance evidence.

| Status | Result |
|---|---|
| `IMPLEMENTED` | Phase 6 workflow and release gates are present in commit `a633be2ddd3c87c84d4304a9fe20218679a08915`. The workflow remains enabled and unchanged. |
| `LOCAL_PASS` | Listed Linux compiler, sanitizer, package, delivery, checksum, SBOM, and Community integrity checks passed locally. |
| `REMOTE_DEFERRED` | GitHub-hosted workflow jobs, CodeQL, artifact upload evidence, and hosted provenance were not run. |
| `RELEASE_BLOCKED` | No customer release, tag, publication, signing, or release-readiness claim is permitted until deferred remote gates pass and required approvals are recorded. |

## Local verification completed

Environment: Ubuntu 26.04 under WSL2, GCC 15.2.0, Clang 21.1.8, CMake
4.2.3, Ninja 1.13.2, and OpenSSL 3.5.5.

The following local profiles passed with warnings treated as errors:

```sh
CC=gcc CXX=g++ cmake -S . -B build-phase6-gcc-static -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
  -DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl \
  -DANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY=ON \
  -DANOSECUREKIT_ENTERPRISE_WARNINGS_AS_ERRORS=ON \
  -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON
cmake --build build-phase6-gcc-static \
  --target enterprise-release-preflight --parallel 4

CC=gcc CXX=g++ cmake -S . -B build-phase6-gcc-shared -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
  -DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl \
  -DANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY=ON \
  -DANOSECUREKIT_ENTERPRISE_WARNINGS_AS_ERRORS=ON \
  -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON
cmake --build build-phase6-gcc-shared \
  --target enterprise-release-preflight --parallel 4

CC=clang CXX=clang++ cmake -S . -B build-phase6-clang-static -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
  -DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl \
  -DANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY=ON \
  -DANOSECUREKIT_ENTERPRISE_WARNINGS_AS_ERRORS=ON \
  -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON
cmake --build build-phase6-clang-static \
  --target enterprise-release-preflight --parallel 4
```

Each aggregate preflight passed Enterprise profile/runtime tests, installed
package consumption, ZIP/TGZ delivery generation, staged and archived manifest
verification, `SHA256SUMS.txt` verification, SPDX 2.3 delivery SBOM validation,
Community v0.4.0 source-offer verification, and CI policy validation.

Sanitizer runtime checks passed:

```sh
CC=clang CXX=clang++ cmake -S . -B build-phase6-sanitizers -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl \
  -DANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY=ON \
  -DANOSECUREKIT_ENTERPRISE_WARNINGS_AS_ERRORS=ON \
  -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON \
  -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer" \
  -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address,undefined" \
  -DCMAKE_SHARED_LINKER_FLAGS="-fsanitize=address,undefined"
ASAN_OPTIONS=detect_leaks=1 UBSAN_OPTIONS=print_stacktrace=1 \
  cmake --build build-phase6-sanitizers \
  --target enterprise-sanitizer-check enterprise-profile-config-check \
    enterprise-runtime-contract-check --parallel 4
```

The non-bundled path also passed: Community v0.4.0 was built and installed,
Enterprise was configured with
`ANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY=OFF`, both packages were
installed to one prefix, and the independent installed consumer built and ran.

The bundled Community subtree has no local diff and remains at Git tree
`9b498f5431f217ac71e8d2e2c92df9e8b0122626`. Delivery verification recursively
matched its generated v0.4.0 source-offer archive to that subtree.

## Remote checks not run

No GitHub-hosted result is claimed for:

- Ubuntu GCC Release static, Ubuntu GCC Release shared, or Ubuntu Clang Release static;
- Ubuntu Clang ASan/UBSan;
- Windows MSVC Release shared;
- macOS AppleClang Release static;
- non-bundled Community consumer;
- CodeQL or any other hosted security-analysis check;
- workflow artifact upload, retention, or download verification;
- hosted signing, attestation, or provenance generation.

The Phase 6 workflow is read-only and does not publish releases or generate
customer-approved provenance. Local delivery archives remain internal test
outputs and are not release artifacts.

## Recovery procedure

1. Restore GitHub-hosted Actions availability without changing or weakening
   `.github/workflows/anosecurekit-enterprise-ci.yml`.
2. Push the reviewed commits to a branch and trigger `AnoSecureKit Enterprise CI`
   through a pull request, push, or `workflow_dispatch`.
3. Require all five build-matrix jobs, the sanitizer job, and the non-bundled
   consumer job to complete successfully at the same source revision.
4. Require the repository or organization CodeQL gate and any other mandatory
   hosted security checks to complete successfully at that revision.
5. Confirm each matrix job uploaded its expected internal delivery artifact;
   download it and verify `SHA256SUMS.txt`, archive `MANIFEST.sha256` files, SPDX
   SBOM contents, build metadata, licenses, and Community source offer.
6. Run the separately approved signing/provenance process. Do not infer
   authenticity from checksums or unsigned workflow artifacts.
7. Record remote run URLs, commit SHA, artifact identities, CodeQL result,
   provenance evidence, legal approval, security approval, and support approval.
8. Remove `RELEASE_BLOCKED` only after every required item above is complete.
