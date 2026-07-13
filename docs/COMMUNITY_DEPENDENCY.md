# AnoSecureKit Community Dependency

- Component: AnoSecureKit Community
- Repository: <https://github.com/anothel/AnoSecureKit-Community>
- Release: `v0.4.0`
- Release commit: `102965bee601f2adfb1b624e8425d1c95aaa8c8d`
- Local alignment archive: `AnoSecureKit-Community-v0.4.0-rc-verified.zip`
- Local archive SHA-256: `dd3b989b0379730fd52b08e94067d15b66d0e62253f63e8a3ed604f4fc259c50`
- Verified: 2026-07-13
- License: Mozilla Public License 2.0 (`MPL-2.0`)
- Integration: bundled, unmodified source under `third_party/anosecurekit-community/`

The bundled tree is the Community v0.4.0 provider-seam baseline. Enterprise uses
its OpenSSL profile directly and uses Community's build-tree external-provider
hook for the future AnoCrypto-C profile.

Before a customer delivery, replace this local alignment record with the exact
project-owned v0.4.0 release-asset filename, checksum, and GitHub attestation
result from the published release audit.

## Update procedure

1. Obtain the project-owned Community source archive and checksum manifest.
2. Verify checksum and provenance against the release tag and commit.
3. Replace the subtree without Enterprise-local modifications.
4. Confirm the subtree matches the verified archive recursively.
5. Run the OpenSSL profile test and the AnoCrypto-C profile fail-closed checks.
