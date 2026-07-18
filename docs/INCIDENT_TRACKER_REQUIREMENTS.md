# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Incident Tracker Requirements

This is the vendor-neutral acceptance contract for a future incident tracking
system. It creates no tracker, project, ticket, customer record, or reporting
channel.

```text
approved incident tracking system: not yet activated
approved private reporting channel: not yet activated
assigned operational roles: none
activation_ready: false
```

## Workflow contract

The exact supported states are:

```text
reported acknowledged triaged confirmed mitigating fixed requalifying closed rejected not-applicable
```

The confirmed path is `reported -> acknowledged -> triaged -> confirmed ->
mitigating -> fixed -> requalifying -> closed`. Triage may instead end in
`rejected` or `not-applicable`. New evidence may reopen any disposition through
an audited append event; history is never rewritten.

Every incident shall have an immutable ID, severity and scope, exact product,
revision, dependency and artifact bindings, non-personal owner/routing roles,
custody and decision-log references, authorization/evidence/artifact impact,
disclosure and notification decisions, next review, closure criteria, reopen
history, and a complete audit trail. Attachments remain in the evidence
repository; the tracker records their canonical references and SHA-256 digests.

Restricted visibility, access audit, complete export, backup/restore, duplicate
linking, and upstream/downstream relationship tracking are mandatory. Closure
requires remediation or safe disposition plus required requalification, but a
tracker state is never a release PASS.

## Fail-closed behavior

The system shall reject missing or unknown workflow states, destructive edits,
personal assignee identity in canonical records, secret material, local paths,
unresolved partial transactions, and success reported for a rate-limited
operation. `degraded`, `unavailable`, `unauthorized`, unknown capability, or
unknown backend status blocks activation and any dependent release decision.
There is no silent file, spreadsheet, email, or local tracker fallback.

Vendor names may be compared later as non-authoritative examples only. No
comparison selects or activates a backend.
