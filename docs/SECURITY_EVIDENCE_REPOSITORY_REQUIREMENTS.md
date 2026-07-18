# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Security Evidence Repository Requirements

This is the vendor-neutral acceptance contract for a future security evidence
repository. It approves no product, account, project, bucket, database,
credential, endpoint, or production use.

```text
approved evidence repository: not yet activated
assigned operational roles: none
activation_ready: false
```

## Required integrity and custody behavior

The repository shall preserve original bytes in immutable or append-only
records. Every stored object shall expose a stable object ID and version ID,
record the ingest SHA-256 as metadata, and bind metadata plus the object/version
identity in a canonical record digest. Retention shall be WORM-capable or
otherwise tamper-evident. Replacement, metadata rewrite, or loss of a prior
version is forbidden.

Storage integrity, record integrity, cryptographic evidence verification, and
release authorization are separate results:

- storage integrity proves the stored bytes still match their ingest digest;
- record integrity proves the append-only metadata/version history is intact;
- a trusted verifier decides whether signing, provenance, or attestation
  evidence is cryptographically valid;
- a release authorizer makes a separately bound decision; and
- the customer gate enforces that decision.

The repository never decides cryptographic validity or release eligibility.

## Security controls

Access shall use RBAC, least privilege, and separate read, write/custody, and
administration authority. It shall retain administrative, data-access, failed
access, export, retention, hold, revocation, and deletion audit logs. Access
reviews and recertification shall be possible without personal identifiers in
repository records.

The backend shall support the five retention classes in
[SECURITY_RECORD_RETENTION_POLICY.md](SECURITY_RECORD_RETENTION_POLICY.md),
legal holds, explicit revocation, approved deletion workflow, and evidence of
every disposition. Deletion shall fail closed when a hold, dependency, audit
record, or approval is unresolved.

Encryption in transit and at rest, controlled data region, backup and disaster
recovery, stable complete export, and a versioned API contract are required.
Restore and export shall preserve original bytes, object/version IDs, metadata,
digests, holds, and audit history.

## Authentication and availability

Credentialless workload identity or short-lived OIDC federation is preferred.
Any exception requires documented authentication approval, rotation,
revocation, outage handling, and secret lifecycle evidence. Static credentials,
secrets, local absolute paths, developer identities, personal accounts, and
silent local storage fallback are forbidden in repository records or fixtures.

`degraded`, `unavailable`, `unauthorized`, unknown capability, unknown status,
or incomplete write state fails closed. Retry requires an idempotency key and
duplicate-write detection. No degraded or unavailable repository may produce a
release PASS.

Vendor names may appear in a later comparison matrix only as examples. They do
not change this contract or imply selection.
