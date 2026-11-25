# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Development Freeze and Change Policy

Enterprise `0.1.0` internal engineering is reopened only for the selected
scope in the [2026-11-25 decision](ENGINEERING_REOPENING_2026_11_25.md). The canonical state is
[CURRENT_STATUS.md](CURRENT_STATUS.md). The retained blocker registry preserves
historical IDs and conditional reopen gates; Jira ASK is the active work queue.

The following freeze record and restrictions remain historical and apply to
work outside the authorized reopening scope.

```text
ENGINEERING_STATUS=CLOSED_AND_FROZEN
ACTIVE_BLOCKER_COUNT=0
ACTIVE_NEXT_WORK=NONE
ACTIVE_RELEASE_ACTION=NONE
FUTURE_WORK=NOT_SELECTED
CUSTOMER_RELEASE_READY=FALSE
```

## Closeout boundary

The documentation-only closeout may record the frozen state and its external
commit identity. After closeout, any code, dependency, product, release,
qualification, support, or operational change requires a new product decision
that explicitly reopens the repository.

For work outside an explicit reopening decision, do not:

- new abstract policy, schema, fixture, or document contract;
- select or implement a speculative vendor adapter or unselected system;
- new customer-release, evidence, or authorization mechanism;
- unsupported profile/capability claim without evidence;
- Community private patch;
- cryptographic primitive implemented inside Enterprise for AnoCrypto-C;
- v1 format or public compatibility change;
- dependency pin, install/export, package, tag, release, or archive action; or
- GA, production, active-support, KCMVP, FIPS, signing, provenance,
  attestation, or external-audit claim.

## Reopen proof

A reopening decision must define product scope, ownership, selected work,
dependency baseline, verification, release boundary, and authorization. Any
subsequent closure must use exact evidence and preserve
`customer_release_ready: false` until an independent release authorization
passes. Historical evidence cannot be promoted silently.

```text
NOW: none
```

The historical NOW queue above remains unchanged; see the reopening decision
for current selected internal engineering work.
