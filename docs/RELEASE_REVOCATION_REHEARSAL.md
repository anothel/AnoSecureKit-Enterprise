# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Release Revocation Rehearsal

This is a decision rehearsal. It does not revoke a release or delete an
artifact. Enterprise `0.1.0` remains unsupported pre-release/internal
qualification material with no customer release.

## Fail-closed action matrix

| Trigger | Qualification | Trusted evidence | Authorization | Artifact action | Re-entry condition |
|---|---|---|---|---|---|
| Community critical defect | `invalidated` | `rejected` | deny | block generation | approved Community revision plus full requalification |
| Enterprise adapter high defect | `not-passed` | `rejected` | deny | block generation | adapter fix plus Windows/WSL regression and partial profile |
| AnoCrypto-C digest compromise | `invalidated` | `rejected` | revoke | test-only withdrawal simulation | new approved package/digest; no fallback; partial profile |
| Signing/trust-root compromise | `invalidated` | `rejected` | revoke | test-only withdrawal simulation | new signing/provenance chain and fresh trusted evidence |
| Hosted qualification invalidation | `not-passed` | `rejected` | deny | block generation | fresh hosted lanes, attestation, and evidence |
| Artifact/SBOM mismatch | `invalidated` | `rejected` | revoke | quarantine/regenerate synthetic output | regenerated artifact set, manifest, SBOM, and evidence |

Concrete denied, revoked, and unavailable authorization states collapse to the
repository decision summary:

```text
release_authorization: denied-or-unavailable
customer_release_ready: false
```

## Simulated sequence

1. Freeze new customer delivery and package generation for affected scope.
2. Identify exact source, dependency, profile, artifact, and evidence bindings.
3. Invalidate affected qualification and trusted evidence.
4. Deny or revoke authorization; never copy old evidence forward.
5. Record expected withdrawal for controlled locations without touching them.
6. Route dependency defects upstream; never patch Community/AnoCrypto-C source here.
7. Consume the approved fix/package and rerun listed local and hosted gates.
8. Regenerate artifact inventory, manifest, checksums, SBOM, attestation,
   signing/provenance, trusted evidence, and authorization.
9. Keep release blocked because this rehearsal supplies none of those external
   production approvals.

Rollback is not rehearsed as an automatic escape: it would require an exact,
unaffected, qualified, unrevoked, authorized artifact. OpenSSL fallback from an
affected AnoCrypto-C profile is forbidden.
