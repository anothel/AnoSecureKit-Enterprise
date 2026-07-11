# AnoSecureKit Community Dependency

- Component: AnoSecureKit Community
- Repository: <https://github.com/anothel/AnoSecureKit-Community>
- Release: `v0.3.0`
- Commit: `ba58d5ba48c8e04ae46cabf50b12588ac4ecfb21`
- Source asset: `anosecurekit-0.3.0-source.zip`
- SHA-256: `2113faa4af0b0a2be75c79afe33356ecff885b6df60b733b8338dc57f2521711`
- Verified: 2026-07-11
- License: Mozilla Public License 2.0 (`MPL-2.0`)
- Integration: bundled, unmodified source under
  `third_party/anosecurekit-community/`
- Consuming target: `anosecurekit::anosecurekit`

Verification used the release `SHA256SUMS.txt` manifest and a local SHA-256
calculation. GitHub provenance verification passed for repository
`anothel/AnoSecureKit-Community`, source ref `refs/tags/v0.3.0`, source commit
`ba58d5ba48c8e04ae46cabf50b12588ac4ecfb21`, signer workflow
`.github/workflows/anosecurekit-ci.yml`, and a GitHub-hosted runner.

This provenance record is Enterprise-owned documentation. It is intentionally
stored outside the bundled MPL-2.0 subtree so that subtree remains identical to
the verified release archive.

## Update procedure

1. Download the next project-owned source archive and `SHA256SUMS.txt` from the
   official Community release.
2. Verify its checksum and GitHub provenance against the release tag and commit.
3. Confirm version, repository identity, package/API identity, and MPL-2.0
   license.
4. Replace the bundled subtree with the extracted archive without modification.
5. Compare normalized paths and SHA-256 digests recursively, then update this
   record and rebuild both supported dependency modes.

## Architectural Role

The bundled `v0.3.0` tree is the verified OpenSSL baseline and the public API,
format, fixture, and compatibility reference. The current Enterprise scaffold
links its final OpenSSL-backed target.

This dependency alone does not implement the AnoCrypto-C profile. Enterprise
must consume a later verified Community provider seam and attach a proprietary
AnoCrypto-C provider without modifying the bundled MPL-2.0 files.
