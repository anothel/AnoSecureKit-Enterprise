# Third-Party Notices

## Bundled: AnoSecureKit Community

This repository bundles `third_party/anosecurekit-community` as its public base
SDK. Those files remain licensed under the Mozilla Public License 2.0. See
`third_party/anosecurekit-community/LICENSE`. Preserve all applicable MPL-2.0
notices and source-code obligations in distributions. Version and verification
details are recorded in `docs/COMMUNITY_DEPENDENCY.md`.

## OpenSSL Profile Dependency

The current Enterprise scaffold and the intended Enterprise OpenSSL profile use
the OpenSSL-backed AnoSecureKit Community final target. OpenSSL is governed by
its own license terms. This repository does not bundle OpenSSL source or
binaries; any delivery that includes them must include the applicable OpenSSL
license and notices.

An Enterprise AnoCrypto-C-only profile must not carry OpenSSL as a hidden
production fallback or transitive provider dependency. Build/test tooling may
have separate clearly documented dependencies.

## Other Bundled Third-Party Components

No other third-party component is bundled outside the AnoSecureKit Community
subtree.

## External Dependency: AnoCrypto-C

AnoCrypto-C is not bundled in this repository or its current distribution. A
future AnoCrypto-C profile will consume a separately supplied external package,
expected through `AnoCryptoC::AnoCryptoC`, and a proprietary Enterprise adapter.
AnoCrypto-C remains governed by its own separate license and commercial terms;
it is not licensed by this repository's `LICENSE` file.
