# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Security Evidence Handling Runbook

This runbook governs policy and synthetic rehearsal only. It does not create
real incident evidence, a reporting channel, customer record, legal hold, or
approved storage system.

## Collect and register

1. Receive through an activated private channel or authorized internal
   escalation; otherwise stop.
2. Minimize personal/customer data and secrets without altering the preserved
   original. Assign non-personal incident, evidence, and custody IDs.
3. Record exact source revision/reference, UTC collection time, owner role,
   sensitivity, access, retention, file size, and SHA-256.
4. Store only in the approved evidence repository. Current state is `not yet
   activated`, so production collection cannot proceed under this repository.

## Transfer and review

The sender and recipient append a contiguous transfer entry. Recompute the
entry digest from canonical fields, bind the prior entry digest, then recompute
the custody digest. The `evidence-custodian` verifies original availability,
size, digest, source binding, access class, and retention class. The
`evidence-reviewer` independently decides trust impact; review does not grant
release authorization.

## Invalidate, revoke, or withdraw

On missing evidence, mismatch, altered chain, unknown custodian, expired
required evidence, affected dependency/revision, compromised trust chain, or
hosted invalidation:

1. stop affected use and delivery;
2. append evidence-invalidation and release-block decisions;
3. reject/unavailable trusted evidence and deny/revoke authorization;
4. preserve the original under retention policy;
5. record test-only withdrawal only in fixtures; never delete or contact a
   customer from a fixture;
6. require new evidence and requalification before closure.

## Archive or dispose

Archive migration preserves content, metadata, format readability, custody
history, and digests. Disposition requires the retention approvals, no active
legal hold, an integrity check, and an appended final decision. Current archive
state is `not yet activated`; no repository file is proof of archival custody.
