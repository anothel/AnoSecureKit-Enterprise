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
source tree exactly reconstructs release tree
`5478a5c37e96aa1017f8f4604234de48c1115d7c`. Community final closeout commit
`298bcbd125cafae26cf54a6ec81c98b7f729b477`, unpublished maintenance `0.4.1`
(`df1936777843415022a97f775c6e61eea6d99cb0`), and parked
`develop/v0.5.0@9fe79dc1e0f8b9951e86c2707c70469611ab43e4` are not included.

## Historical source-offer disposition

One archived source-offer transformed
`src/internal/secure_wipe.hpp` from LF to CRLF. The current exact-tree file
SHA-256 is
`a38ec0033c027c501b7dc75da37a89283bae2aafc791434868cccae9f71fc651`;
the archived file SHA-256 is
`cacb460f19926a82538c9f64a9527bcc5c024708cbfd2d463c85a49fa77ff0e2`.
The archived source-offer ZIP SHA-256 is
`d69379e16a306c3bdfdee15366c3ebbb92e71c415444b68cc4892aae1d40c885`.

```text
CURRENT_COMMUNITY_V0_4_0_TREE=EXACT
CURRENT_ENTERPRISE_SUBTREE=EXACT
HISTORICAL_SOURCE_OFFER=ARCHIVE_ONLY_NON_CANONICAL
HISTORICAL_SOURCE_OFFER_BYTE_EXACT_CLAIM=INVALID
HISTORICAL_ARTIFACT_REPAIR=NOT_SELECTED
HISTORICAL_ARTIFACT_REPUBLICATION=NOT_AUTHORIZED
CLOSEOUT_BLOCKER=NO
```

The historical ZIP, checksum, manifest, original hashes, and mismatch evidence
remain unchanged. They are not canonical exact-source evidence or
customer-release evidence. No validator exception is authorized. A final
closeout source ZIP, if separately authorized later, must be generated from the
exact final Git closeout commit tree.

A production release audit should additionally retain the upstream
project-owned Community release-asset checksum and GitHub attestation evidence.
Those external release records are not replaced by the locally generated
internal-delivery checksum.

## Inherited public limitation

Public Community `v0.4.0` can create generic CLI key/plaintext output with POSIX
mode `0644` under `umask 022`. Enterprise inherits that exact baseline
limitation. Its unpublished `0.4.1` fix is not included.

Dependency update work is not selected. Any future update requires a new product
decision and complete requalification.
