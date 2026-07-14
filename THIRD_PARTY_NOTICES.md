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

AnoCrypto-C is not bundled in this repository or its current distribution. The
pinned external baseline is licensed under MPL-2.0 and is not relicensed by
Enterprise. Preserve applicable MPL source and notice obligations. Commercial
or private-repository use does not remove those obligations. Legal review is
required before customer delivery; this notice is not legal advice. Identity
details are recorded in `docs/ANOCRYPTO_C_PINNED_CONTRACT.md`.
