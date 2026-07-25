# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Enterprise 0.1.0 Closeout Blocker Registry

[PRE_GA_BLOCKER_REGISTRY.json](PRE_GA_BLOCKER_REGISTRY.json) is the authoritative
machine-readable historical ID/status registry. This document is its human
view. [CURRENT_STATUS.md](CURRENT_STATUS.md) is authoritative for the current
lifecycle and closeout state. The registry does not approve work, release,
trusted evidence, an artifact, a system, or a support-state change.

```text
support: unsupported pre-release/internal qualification
OpenSSL local qualification: PASS
OpenSSL hosted qualification: not passed / BLOCKED_EXTERNAL
AnoCrypto-C profile: local compatibility only; exact package blocked
actual operational systems: inactive
assigned operational roles: none
activation_ready: false
cryptographic evidence: unavailable
trusted evidence: unavailable
release authorization: denied-or-unavailable
customer_release_ready: false
engineering_status: CLOSED_AND_FROZEN
active_blocker_count: 0
active_next_work: none
```

## Record contract

Every blocker has `blocker_id`, `title`, `category`, `scope`, `profile`,
`status`, `severity`, `owner_repository`, `owner_role`, `external_dependency`,
`blocking_gate`, `required_evidence`, `completion_condition`, `deferred_reason`,
and `last_verified_revision`.

Allowed categories are `external`, `organizational`, `technical`, `upstream`,
`policy`, and `evidence`. Allowed statuses are `open`, `blocked-external`,
`waiting-upstream`, `waiting-decision`, `in-progress`, `verified-closed`, and
`not-applicable`. Unknown values fail closed.

`last_verified_revision` identifies the exact source revision whose blocker
state/evidence was last audited. The closeout audit binds it to engineering
baseline `dc87eae600713e482f490910233cb666b8f706b8`. Closing a blocker requires
exact evidence; local PASS never substitutes for hosted PASS.

Existing lowercase `status` values and `next_work` routing are retained to keep
historical schema, IDs, negative contract tests, and evidence meaning intact.
They are not active work authorization. Non-closed records carry an explicit
`closeout_classification` in `deferred_reason`; `verified-closed` records derive
their classification from evidenced status.

## OpenSSL GA scope

| Blocker ID | Category | Status | Queue |
|---|---|---|---|
| `PGA-OSSL-LOCAL-WINDOWS` | technical | `verified-closed` | closed |
| `PGA-OSSL-LOCAL-WSL` | technical | `verified-closed` | closed |
| `PGA-OSSL-HOSTED-UBUNTU` | external | `blocked-external` | EXTERNAL |
| `PGA-OSSL-HOSTED-WINDOWS` | external | `blocked-external` | EXTERNAL |
| `PGA-OSSL-HOSTED-MACOS` | external | `blocked-external` | EXTERNAL |
| `PGA-OSSL-CODEQL` | external | `blocked-external` | EXTERNAL |
| `PGA-OSSL-HOSTED-ARTIFACT-GENERATION` | external | `blocked-external` | EXTERNAL |
| `PGA-OSSL-HOSTED-ARTIFACT-DOWNLOAD` | external | `blocked-external` | EXTERNAL |
| `PGA-OSSL-ATTESTATION-GENERATION` | external | `blocked-external` | EXTERNAL |
| `PGA-OSSL-ATTESTATION-CRYPTO-VERIFY` | evidence | `blocked-external` | EXTERNAL |
| `PGA-OSSL-TRUSTED-EVIDENCE-CURRENT-REVISION` | evidence | `blocked-external` | EXTERNAL |
| `PGA-OSSL-RELEASE-AUTHORIZATION-ARTIFACT-SET` | evidence | `blocked-external` | EXTERNAL |
| `PGA-OSSL-PRIVATE-REPORTING-DECISION` | organizational | `waiting-decision` | DECISION |
| `PGA-OSSL-OPERATIONAL-ROLE-ASSIGNMENT` | organizational | `waiting-decision` | DECISION |
| `PGA-OSSL-SUPPORT-STATE-APPROVAL` | policy | `waiting-decision` | DECISION |
| `PGA-OSSL-SECURITY-SYSTEM-DECISION-OR-WAIVER` | policy | `waiting-decision` | DECISION |

The two local closures are bound to the exact audited result in
[SECURITY_SYSTEM_ACTIVATION_READINESS_RESULT.md](SECURITY_SYSTEM_ACTIVATION_READINESS_RESULT.md):
Windows CTest 15/15 plus preflight PASS, and WSL CTest 15/15 plus preflight
PASS. They close only local qualification blockers. They do not close any
hosted, evidence, authorization, operational, or support blocker.

## AnoCrypto-C enablement scope

| Blocker ID | Owner repository | Status | Queue |
|---|---|---|---|
| `PGA-ANO-HKDF-SHA256` | AnoCrypto-C | `waiting-upstream` | UPSTREAM |
| `PGA-ANO-SCRYPT` | AnoCrypto-C | `waiting-upstream` | UPSTREAM |
| `PGA-ANO-AES256-GCM` | AnoCrypto-C | `waiting-upstream` | UPSTREAM |
| `PGA-ANO-STREAMING-AEAD` | AnoCrypto-C | `waiting-upstream` | UPSTREAM |
| `PGA-ANO-CAPABILITY-STATUS-FAILURE-CONTRACT` | AnoCrypto-C | `waiting-upstream` | UPSTREAM |
| `PGA-ANO-FORCED-FAILURE-SEAMS` | AnoCrypto-C | `waiting-upstream` | UPSTREAM |
| `PGA-ANO-APPROVED-PACKAGE-DIGEST` | AnoCrypto-C | `waiting-upstream` | UPSTREAM |
| `PGA-ANO-STATIC-PACKAGE` | AnoCrypto-C | `waiting-upstream` | UPSTREAM |
| `PGA-ANO-SHARED-PACKAGE` | AnoCrypto-C | `waiting-upstream` | UPSTREAM |
| `PGA-ANO-ENTERPRISE-ADAPTER-PARITY` | AnoSecureKit-Enterprise | `waiting-upstream` | UPSTREAM |
| `PGA-ANO-INSTALL-EXPORT-CPACK` | AnoSecureKit-Enterprise | `waiting-upstream` | UPSTREAM |
| `PGA-ANO-HOSTED-QUALIFICATION` | AnoSecureKit-Enterprise | `blocked-external` | EXTERNAL |
| `PGA-ANO-CUSTOMER-AUTHORIZATION` | AnoSecureKit-Enterprise | `blocked-external` | EXTERNAL |

These records do not block the closed Enterprise engineering state. Current
product policy does not require both profiles to become GA together.
AnoCrypto-C has seven-capability local P3-06 parity evidence against
`c101c9655f881044c14d8efbc20ea94a2e84f30b`. The P3-06 contract is
`89e16a261ab7696d9489167d7403d9f2c704629e`. Phase 1 archive
`98f544a574f70b387c300f171243b4e87174937a` was not requalified by
Enterprise. Enterprise must not implement upstream primitives or use OpenSSL
fallback.

## Closeout classifications

| Closeout classification | Count | Historical blocker IDs |
|---|---:|---|
| `VERIFIED_CLOSED` | 2 | `PGA-OSSL-LOCAL-WINDOWS`, `PGA-OSSL-LOCAL-WSL` |
| `UPSTREAM_IMPLEMENTED_NOT_REQUALIFIED_ARCHIVED` | 10 | `PGA-ANO-HKDF-SHA256`, `PGA-ANO-SCRYPT`, `PGA-ANO-AES256-GCM`, `PGA-ANO-STREAMING-AEAD`, `PGA-ANO-CAPABILITY-STATUS-FAILURE-CONTRACT`, `PGA-ANO-FORCED-FAILURE-SEAMS`, `PGA-ANO-APPROVED-PACKAGE-DIGEST`, `PGA-ANO-STATIC-PACKAGE`, `PGA-ANO-SHARED-PACKAGE`, `PGA-ANO-ENTERPRISE-ADAPTER-PARITY` |
| `DEFERRED_EXTERNAL_NOT_SELECTED` | 11 | `PGA-OSSL-HOSTED-UBUNTU`, `PGA-OSSL-HOSTED-WINDOWS`, `PGA-OSSL-HOSTED-MACOS`, `PGA-OSSL-CODEQL`, `PGA-OSSL-HOSTED-ARTIFACT-GENERATION`, `PGA-OSSL-HOSTED-ARTIFACT-DOWNLOAD`, `PGA-OSSL-ATTESTATION-GENERATION`, `PGA-OSSL-ATTESTATION-CRYPTO-VERIFY`, `PGA-OSSL-TRUSTED-EVIDENCE-CURRENT-REVISION`, `PGA-OSSL-RELEASE-AUTHORIZATION-ARTIFACT-SET`, `PGA-ANO-HOSTED-QUALIFICATION` |
| `DEFERRED_DECISION_NOT_SELECTED` | 5 | `PGA-OSSL-PRIVATE-REPORTING-DECISION`, `PGA-OSSL-OPERATIONAL-ROLE-ASSIGNMENT`, `PGA-OSSL-SUPPORT-STATE-APPROVAL`, `PGA-OSSL-SECURITY-SYSTEM-DECISION-OR-WAIVER`, `PGA-ANO-CUSTOMER-AUTHORIZATION` |
| `KNOWN_LIMITATION_NOT_SELECTED` | 1 | `PGA-ANO-INSTALL-EXPORT-CPACK` |

```text
TOTAL_HISTORICAL_BLOCKER_IDS=29
ACTIVE_BLOCKER_COUNT=0
ACTIVE_NEXT_WORK=NONE
```

`UPSTREAM_IMPLEMENTED_NOT_REQUALIFIED_ARCHIVED` does not claim Enterprise
validation against `98f544a...`. `KNOWN_LIMITATION_NOT_SELECTED` records the
AnoCrypto-C package's missing `find_dependency(Threads)` requirement for any
future install/export or customer-release reopening.

## Historical routing and active-work projection

```text
NOW:
none

EXTERNAL:
historical external reopen gates retained; not selected

UPSTREAM:
historical upstream/package reopen gates retained; not selected

DECISION:
historical organizational/release decisions retained; not selected

LATER:
historical optional items retained; not selected
```

The JSON arrays preserve legacy routing. Only `NOW` represents active local
work, and it is empty. EXTERNAL, UPSTREAM, DECISION, and LATER do not create an
active roadmap or release action.

## Archive-only source-offer limitation

The LF/CRLF mismatch for archived
`src/internal/secure_wipe.hpp` is
`HISTORICAL_SOURCE_OFFER=ARCHIVE_ONLY_NON_CANONICAL` and
`CLOSEOUT_BLOCKER=NO`. The ZIP, checksum, manifest, original SHA-256 values,
and mismatch evidence remain archived unchanged. They are not canonical source
or customer-release evidence; repair and republication are not selected.
