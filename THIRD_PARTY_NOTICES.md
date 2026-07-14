# Third-Party Notices

## Bundled: AnoSecureKit Community

This repository bundles `third_party/anosecurekit-community` as its public base
SDK. Those files remain licensed under the Mozilla Public License 2.0. See
`third_party/anosecurekit-community/LICENSE`. Preserve all applicable MPL-2.0
notices and source-code obligations in distributions. Version and verification
details are recorded in `docs/COMMUNITY_DEPENDENCY.md`.

## Dependency through Community: OpenSSL

AnoSecureKit Community requires OpenSSL Crypto 3.0 or newer as its current
production backend. OpenSSL is governed by its own license terms. This
repository does not bundle OpenSSL source or binaries; any distribution that
includes them must include the applicable OpenSSL license and notices.

## Other bundled third-party components

No other third-party component is bundled outside the AnoSecureKit Community
subtree.

## Optional external dependency: AnoCrypto-C

AnoCrypto-C is not bundled in this repository or its current distribution. If
supplied externally, it remains proprietary software governed by separate
commercial terms. It is not licensed by this repository's `LICENSE` file.
