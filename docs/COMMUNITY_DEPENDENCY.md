# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# AnoSecureKit Community Dependency

- Component: AnoSecureKit Community
- Repository: <https://github.com/anothel/AnoSecureKit-Community>
- Release: `v0.4.0`
- Release commit: `694459ebe497d15ba75ef76a52fa7c36ddd7bcce`
- Git tree: `5478a5c37e96aa1017f8f4604234de48c1115d7c`
- Upstream source ZIP SHA-256:
  `a9b1e0bf6baca93509c4706b38066a539c5324151b338859063ebb8cf3cffeb5`
- License: Mozilla Public License 2.0 (`MPL-2.0`)
- Integration: bundled, unmodified source under `third_party/anosecurekit-community/`

The annotated `v0.4.0` tag resolves to the release commit above. The bundled
source tree exactly reconstructs the release commit tree. The upstream source
ZIP contains 178 matching tracked files and intentionally excludes only the
four `.github` workflow/dependency files. The bundled tree is the Community
v0.4.0 provider-seam baseline used by the
Enterprise OpenSSL profile and by Community's build-tree external-provider hook
for the future AnoCrypto-C profile.

The Enterprise delivery gate creates a separate
`anosecurekit-community-0.4.0-source-offer.zip` and recursively verifies every
file and SHA-256 digest against the bundled source tree. The internal-delivery
`SHA256SUMS.txt` covers that source-offer archive.

A production release audit should additionally retain the upstream
project-owned Community release-asset checksum and GitHub attestation evidence.
Those external release records are not replaced by the locally generated
internal-delivery checksum.

## Update procedure

1. Obtain the project-owned Community source archive and checksum manifest.
2. Verify checksum and provenance against the release tag and commit.
3. Replace the subtree without Enterprise-local modifications.
4. Confirm the subtree matches the verified archive recursively.
5. Update this document with the new release and provenance record.
6. Run the OpenSSL profile package/delivery gates and AnoCrypto-C fail-closed checks.
