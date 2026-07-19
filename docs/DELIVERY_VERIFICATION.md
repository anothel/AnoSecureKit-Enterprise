# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# OpenSSL Profile Delivery Verification

The verified Enterprise OpenSSL internal-delivery staging directory contains:

- ZIP and TGZ install archives created through CPack;
- a separate AnoSecureKit Community v0.4.0 source-offer archive;
- `LICENSE` and `THIRD_PARTY_NOTICES.md`;
- `OPENSSL_PROFILE_SUPPORT_POLICY.md`, `SUPPORTED_CONFIGURATION_MATRIX.md`, and
  `DEFERRED_CI_STATUS.md`;
- the `anosecurekit_enterprise_info` diagnostic executable;
- `BUILD_METADATA.txt`;
- the release authorization policy and default-deny package metadata;
- an SPDX 2.3 delivery SBOM;
- `SHA256SUMS.txt` covering every top-level delivery asset except itself.

Generate and verify the staged delivery with:

```sh
cmake --build build --target enterprise-delivery-check
```

The target verifies both binary archives by extraction, confirms that Community
and Enterprise CMake packages and public headers are present, checks that private
runtime-contract headers and Enterprise implementation sources are absent, and
verifies the independent MPL-covered Community source-offer archive.

`SHA256SUMS.txt` and the directory `MANIFEST.sha256` detect modifications. They
do not authenticate the publisher. These internal assets are not a customer
release. Customer release still requires hosted qualification, a separate
signing/provenance process, and legal/security/support approval.

`enterprise-release-authorization-check` binds a separately supplied record to
the staged `MANIFEST.sha256` and the top-level artifact set through the digest of
`SHA256SUMS.txt`. It is deliberately not part of internal artifact generation;
the repository default record denies customer release.

The exact evidence schema, canonical digest, complete artifact inventory rules,
and fail-closed signing/provenance boundary are defined in
`TRUSTED_RELEASE_EVIDENCE_POLICY.md`.

## AnoCrypto-C P3-06 boundary

P3-06 completes the current primitive and Community-format engineering parity
checkpoint. The AnoCrypto-C profile still has no install/export/CPack path and
cannot produce this delivery.

Before a future AnoCrypto-C delivery profile may be enabled, verification must
cover:

1. an approved exact AnoCrypto-C package and source identity;
2. the exact Community source identity and MPL-2.0 source offer;
3. hosted supported-platform builds and tests;
4. cross-platform proof of no OpenSSL runtime linkage;
5. signed artifacts and verified attestations;
6. SBOM, notices, checksums and reproducible package contents;
7. explicit release authorization.

A parity checkpoint must not be represented as production release evidence.

## CI gate

The private GitHub Actions workflow is configured to run the aggregate
`enterprise-release-preflight` target on Linux, Windows, and macOS. Verified
delivery directories are retained as short-lived internal workflow artifacts
only. The workflow has read-only repository permissions and does not publish a
GitHub Release.
