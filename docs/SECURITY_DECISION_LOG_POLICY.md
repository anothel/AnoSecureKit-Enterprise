# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Security Decision Log Policy

Material incident decisions are append-only, machine-readable records. The
`incident-commander` owns sequence and rationale; the named reviewer confirms
the decision within role authority. Fixtures contain roles, never names or
email addresses.

## Test-only record contract

Every JSONL record requires:

```text
schema_version decision_id incident_id sequence decided_at decision_type
decision rationale decided_by_role reviewed_by_role evidence_references
affected_product affected_revision affected_profile qualification_action
evidence_action authorization_action artifact_action notification_action
next_review_at status previous_decision_digest decision_digest test_only
```

The fixture also records `trusted_evidence_status`,
`release_authorization_status`, and `customer_release_ready` so the fail-closed
result is executable rather than inferred.

Allowed decision types are `triage`, `severity`, `mitigation`, `release-block`,
`artifact-withdrawal`, `evidence-invalidation`, `authorization-revocation`,
`dependency-escalation`, `disclosure`, and `incident-closure`. Unknown fields,
types, values, roles, or status fail closed. Rationale and evidence references
must be non-empty; every evidence reference must resolve to a validated custody
record.

Sequence starts at one and is contiguous. Each canonical decision digest uses
the fixed schema order excluding only `decision_digest`; the previous digest
must equal the prior record digest. Corrections are new records, not edits.

## Required decision path

Each confirmed A-F tabletop history records initial triage, severity,
release-block, routing, mitigation/fix, required requalification, and closure
or an explicit unresolved state. Closure is forbidden until a prior
requalification decision cites validated evidence.

Critical/high incidents cannot allow delivery. Compromised evidence cannot be
trusted/verified. Revoked authorization cannot coexist with customer readiness.
Affected Community defects route to `community-liaison` without a private
subtree patch. AnoCrypto-C package defects route to `anocrypto-c-liaison`,
require an upstream replacement, and forbid OpenSSL fallback. Enterprise
adapter defects remain Enterprise-owned. Trust-chain compromise rejects prior
signing/provenance evidence, revokes authorization, records test-only artifact
withdrawal, and requires a new verified chain before any later authorization.

All checked-in histories end fail closed:

```text
trusted_evidence_status: rejected or unavailable
release_authorization_status: denied or revoked
customer_release_ready: false
```
