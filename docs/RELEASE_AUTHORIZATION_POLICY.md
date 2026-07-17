# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# AnoSecureKit Enterprise Release Authorization Policy

Customer release requires an explicit JSON authorization record. Absence,
malformed input, unknown fields or values, stale bindings, incomplete evidence,
revocation, expiry, and a dirty or mismatched source worktree all fail closed.
The repository default is
`release/customer-release-authorization.json`, whose decision is `deny`.

## Record schema version 1

Every field is required; extra fields are rejected.

| Field | Contract |
|---|---|
| `schema_version` | String `1`. |
| `decision` | `deny` or `allow`; default is `deny`. |
| `product` | Exact string `AnoSecureKit Enterprise`. |
| `enterprise_version`, `community_version` | Exact build inputs. |
| `community_tree`, `source_revision` | Full lowercase 40-character Git SHAs. |
| `backend_profile`, `provider_family` | Exact build values; only complete `openssl`/`openssl` may allow release. |
| `qualification_status` | `qualified` is required for allow. |
| `hosted_evidence_status`, `hosted_evidence_reference` | `passed` and `github-actions-run:<id>` are required for allow. |
| `codeql_required`, `codeql_status` | Must match policy; required CodeQL must be `passed`. |
| `artifact_manifest_digest` | SHA-256 of staged install `MANIFEST.sha256`. |
| `artifact_set_digest` | SHA-256 of top-level `SHA256SUMS.txt`, which binds each delivery asset digest. |
| `trusted_evidence_digest` | Canonical SHA-256 emitted by the strict trusted release evidence verifier. |
| `signing_evidence_status`, `signing_evidence_reference` | `verified` and `signing-evidence:sha256:<digest>` are required for allow. |
| `provenance_evidence_status`, `provenance_evidence_reference` | `verified` and `provenance-evidence:sha256:<digest>` are required for allow. |
| `authorization_status` | `active` is required; `revoked` is always rejected. |
| `authorized_by` | Stable non-personal `role:<identifier>`. |
| `authorized_at`, `expires_at` | UTC `YYYY-MM-DDTHH:MM:SSZ`; allow records must expire. Deny records use `null`. |
| `reason` | Non-empty policy reason; local absolute paths and secret-like data are rejected. |
| `test_only` | Production authorization requires `false`; positive tests use `true`. |

Known non-passing evidence states include `deferred`, `not-run`,
`blocked-external`, `unverified`, `partial`, and `unavailable`. They never permit
an allow decision. Unknown states and schema versions are rejected.

## Commands and artifact binding

Run contract and negative tests:

```sh
cmake --build build --target enterprise-release-authorization-contract-check
```

Create and verify internal artifacts first, obtain separately approved hosted,
CodeQL, signing, provenance, and role authorization evidence, then point a fresh
configure at the externally supplied evidence and authorization records:

```sh
cmake --build build --target enterprise-delivery-check
cmake -S . -B build \
  -DANOSECUREKIT_ENTERPRISE_TRUSTED_RELEASE_EVIDENCE_RECORD=<evidence.json> \
  -DANOSECUREKIT_ENTERPRISE_RELEASE_AUTHORIZATION_RECORD=<record.json>
cmake --build build --target enterprise-release-authorization-check
cmake --build build --target enterprise-customer-delivery-check
```

The authorization check never creates or edits a record. It compares
`trusted_evidence_digest` with the verifier's canonical digest. Production allow
also requires `cryptographic_evidence=verified` and `trusted_evidence=verified`
from the external adapter. No hosted attestation exists, so the current record
still denies release. Reference strings never self-attest. Only the
authorization contract's `test_only: true` fixture can pass without production
cryptographic evidence, and only inside that test harness.

A distributed allow record must also be covered by the final detached release
manifest and publisher signature. Embedding it inside the artifact set it binds
would create a checksum cycle.

Current status:

```text
authorization: denied or unavailable
customer_release_ready: false
```
