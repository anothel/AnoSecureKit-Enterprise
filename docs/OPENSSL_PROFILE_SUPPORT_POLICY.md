# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# AnoSecureKit Enterprise OpenSSL Profile Support Policy

## Status contract

| Term | OpenSSL profile meaning |
|---|---|
| `IMPLEMENTED` | Enterprise policy, diagnostics, install/export, and internal delivery consume the Community OpenSSL provider. |
| `LOCAL_PASS` | Recorded Linux local qualification checks passed. |
| `REMOTE_DEFERRED` | GitHub-hosted platform, CodeQL, artifact-download, signing, and provenance checks have not run. |
| `RELEASE_BLOCKED` | Internal delivery may be generated, but no customer release or customer-support claim is approved. |

The Enterprise OpenSSL profile is `IMPLEMENTED` and `LOCAL_PASS`. Remote
qualification is `REMOTE_DEFERRED`; customer release remains `RELEASE_BLOCKED`.
A deferred hosted check is not a cryptographic failure.

## Source and dependency ownership

The profile consumes verified AnoSecureKit Community `v0.4.0`. Community owns
the common public API, formats, tests, and OpenSSL cryptographic provider.
OpenSSL implementation changes and cryptographic defect fixes belong in
Community. Enterprise does not privately patch the bundled Community files,
duplicate its provider, include OpenSSL headers, call OpenSSL cryptographic
symbols, or link `OpenSSL::Crypto` from Enterprise-owned targets.

Supported dependency methods are:

- bundled, verified, unmodified Community source under
  `third_party/anosecurekit-community/`;
- an installed Community CMake package, for the already-supported non-bundled
  OpenSSL integration.

Enterprise reaches OpenSSL through `anosecurekit::anosecurekit`; it does not
provide an Enterprise-owned OpenSSL provider. OpenSSL runtime version discovery
is not added to Enterprise diagnostics because that would create direct
Enterprise/OpenSSL coupling. Dependency requirements come from Community
metadata.

## Qualification and support scope

Recorded local evidence covers Ubuntu 26.04 under WSL2 on x86-64 with GCC
15.2.0 Release static and shared linkage, Clang 21.1.8 Release static linkage,
and OpenSSL 3.5.5. The installed-package consumer, non-bundled Community path,
and internal ZIP/TGZ delivery set passed locally. Exact configurations and
evidence are in [SUPPORTED_CONFIGURATION_MATRIX.md](SUPPORTED_CONFIGURATION_MATRIX.md).

GitHub-hosted Ubuntu, Windows MSVC, macOS AppleClang, CodeQL, hosted artifact
download verification, signing, attestation, and provenance execution remain
`REMOTE_DEFERRED`; attestation generation is only configured. No pass or
customer-support claim is made for them. Static
and shared support is therefore limited to the recorded local rows; no other
OS, architecture, compiler, linkage, or OpenSSL source is qualified by
inference.

Enterprise support is evidence-based: a configuration becomes customer
supported only after its required local and hosted qualification evidence,
security gates, artifact verification, provenance, and required approvals are
recorded at one source revision. Current customer support and release readiness
remain `RELEASE_BLOCKED`.

## Internal delivery and customer release

The current delivery gate creates internal verification assets: install ZIP
and TGZ archives with a manifest, a separate Community source offer, checksums,
and an SPDX 2.3 SBOM. These are `LOCAL_PASS` evidence, not a customer release.
They must not be published, signed as customer artifacts, tagged, or described
as customer-ready while `RELEASE_BLOCKED` applies.

## Notices, updates, and rollback

Community files remain MPL-2.0; preserve the bundled Community license, source
offer, and applicable notices. OpenSSL uses its own license terms; preserve the
applicable OpenSSL license and notices whenever OpenSSL is distributed. See
`LICENSE`, `THIRD_PARTY_NOTICES.md`, and `COMMUNITY_DEPENDENCY.md`.

OpenSSL security-update qualification and rollback inherit Community policy.
Enterprise consumes a Community-approved update only after the applicable
Community cryptographic, compatibility, package, and release checks pass, then
reruns the Enterprise qualification gates. Roll back through Community to a
safe last-known-good version; never privately patch Community or roll back to a
version affected by the security issue. If no safe qualified version exists,
keep the customer release blocked.
