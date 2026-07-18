# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Security Evidence Custody Policy

## Current operating state

```text
approved evidence repository:
not yet activated

approved incident tracking system:
not yet activated

approved long-term archive:
not yet activated
```

Repository fixtures are synthetic contract tests. They are not an approved
repository, incident system, archive, production record, legal hold, customer
record, or release authorization.

## Evidence classification

| Type | Owner role | Source | Expected format | Sensitivity | Integrity mechanism | Retention class | Access class | Revocation/invalidation | Release-blocking relevance |
|---|---|---|---|---|---|---|---|---|---|
| `source snapshot` | `product-owner` | Exact reviewed source revision | Immutable archive plus revision | internal | SHA-256 and revision binding | `security-record` | incident-response | Invalidate affected revision | Blocks affected build |
| `build log` | `product-owner` | Qualified build lane | Text log | internal | SHA-256 and workflow binding | `operational` | incident-response | Invalidate failed/altered lane | Blocks required lane |
| `test result` | `product-owner` | Qualified test lane | Structured result plus log | internal | SHA-256 and source binding | `operational` | incident-response | Invalidate failed/altered result | Blocks required test |
| `workflow log` | `evidence-reviewer` | Hosted workflow | Provider export/reference | internal | Provider identity, run, revision, SHA-256 | `security-record` | evidence-review | Reject invalidated hosted run | Blocks required hosted evidence |
| `artifact` | `product-owner` | Delivery build | ZIP, TGZ, or installed tree | confidential | Manifest and SHA-256 inventory | `release-evidence` | release-control | Withdraw affected artifact | Blocks exact artifact |
| `manifest` | `product-owner` | Delivery packaging | Canonical manifest | internal | SHA-256 and inventory verification | `release-evidence` | release-control | Invalidate mismatched set | Blocks artifact set |
| `checksum` | `evidence-reviewer` | Approved build/package process | Lowercase SHA-256 record | internal | Independent recomputation | `release-evidence` | evidence-review | Revoke with bound object | Blocks digest mismatch |
| `SBOM` | `product-owner` | Delivery packaging | SPDX 2.3 JSON | internal | SHA-256 and package binding | `release-evidence` | release-control | Regenerate after scope change | Blocks missing/mismatched SBOM |
| `attestation` | `evidence-reviewer` | Approved hosted identity | Verifier-supported bundle | internal | External cryptographic verification | `release-evidence` | evidence-review | Reject revoked identity/trust root | Blocks required attestation |
| `provenance` | `evidence-reviewer` | Approved hosted workflow | SLSA provenance statement | internal | External cryptographic verification | `release-evidence` | evidence-review | Reject altered/revoked chain | Blocks required provenance |
| `release authorization` | `release-authorizer` | Separate approved decision | Canonical schema v1 JSON | confidential | Canonical digest and evidence binding | `release-evidence` | release-control | Deny, expire, or revoke | Always release-blocking |
| `dependency package` | owning dependency liaison | Approved Community revision or AnoCrypto-C package | Source tree or package plus identity | internal | Revision/package SHA-256 | `security-record` | incident-response | Revoke affected identity | Blocks affected profile |
| `vulnerability report` | `security-intake-owner` | Activated private intake | Original report plus minimized metadata | restricted | Original preservation and custody digest | `security-record` | restricted-incident | Preserve original; invalidate derived copy | Blocks when material impact is unresolved |
| `triage note` | `incident-commander` | Incident analysis | Decision-linked text/record | confidential | Decision digest chain | `security-record` | incident-response | Supersede, never rewrite history | May create release block |
| `incident communication` | `customer-communications-owner` | Approved incident decision | Approved message record | restricted | Approval and custody binding | `security-record` | restricted-incident | Withdraw/correct through new record | Blocks when notice decision is pending |
| `revocation record` | `evidence-reviewer` | Evidence/artifact response | Canonical decision record | confidential | Decision digest and object binding | `release-evidence` | release-control | Append replacement; never erase | Blocks revoked object |
| `decision log` | `incident-commander` | Incident decision process | Canonical digest-linked JSONL | confidential | Previous/record SHA-256 chain | `security-record` | incident-response | Append correction; altered history rejected | Controls all recorded blocks |

Sensitivity and access are minimums; applicable law or an approved case may
raise them. No row activates a system, channel, support promise, or customer
processing.

## Test-only custody contract

Each record contains `schema_version`, unique `record_id`, `incident_id`,
unique `evidence_id`, `evidence_type`, `source_revision`, relative
`source_reference`, `collected_at`, `collected_by_role`, `custodian_role`,
`sha256`, non-negative bounded `size`, `sensitivity`, `retention_class`,
`access_class`, `transfer_history`, `integrity_status`, `revocation_status`,
`final_disposition`, `custody_digest`, and `test_only`.

Each transfer contains contiguous `sequence`, role endpoints, UTC time,
non-empty reason, `previous_entry_digest`, and `entry_digest`. CMake's native
canonical string construction and `string(SHA256)` are the repository checksum
mechanism: each entry binds its predecessor; `custody_digest` binds the fixed
schema order excluding only its own value. The validator also recomputes the
referenced synthetic file digest and size and confirms its exact source
revision marker. No new cryptographic algorithm is implemented.

Duplicate IDs, gaps, reorder, digest mismatch, missing original evidence,
unknown roles/types/status, future collection, unsafe size, personal data,
secret-like content, absolute/local paths, missing test-only status, or a
production-use attempt fail closed.

## Invalidation and release gate

Broken custody, altered history, missing/expired/revoked evidence, affected
Community revision, revoked AnoCrypto-C digest, compromised signing/verifier/
trust root, invalidated hosted evidence, or authorization/evidence mismatch
produces:

```text
trusted_evidence: rejected or unavailable
release_authorization: denied or revoked
customer_release_ready: false
```

Corrections are appended as new decisions. Original records are preserved under
their retention class; no fixture can authorize release or customer delivery.
