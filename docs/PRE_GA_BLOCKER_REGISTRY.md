# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Enterprise 0.1.0 Pre-GA Blocker Registry

[PRE_GA_BLOCKER_REGISTRY.json](PRE_GA_BLOCKER_REGISTRY.json) is the authoritative
machine-readable registry. This document is its human view. The registry does
not approve release, create trusted evidence, authorize an artifact, activate a
system, or change support state.

```text
support: unsupported pre-release/internal qualification
OpenSSL local qualification: PASS
OpenSSL hosted qualification: not passed / BLOCKED_EXTERNAL
AnoCrypto-C profile: partial
actual operational systems: inactive
assigned operational roles: none
activation_ready: false
cryptographic evidence: unavailable
trusted evidence: unavailable
release authorization: denied-or-unavailable
customer_release_ready: false
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
state/evidence was last audited. A policy-only registry commit cannot contain
its own Git object ID, so the validator requires that revision to exist and be
an ancestor of the current source. Closing a blocker requires new exact
evidence and a new audit; local PASS never substitutes for hosted PASS.

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

## AnoCrypto-C future-profile scope

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

These do not block completion of OpenSSL-profile engineering. Current product
policy does not require both profiles to reach GA together. AnoCrypto-C remains
`partial`; Enterprise must not implement upstream cryptographic primitives or
use OpenSSL fallback.

## Next-work queue

```text
NOW:
none

EXTERNAL:
GitHub billing/spending limit, hosted runners, CodeQL, hosted artifacts,
attestation, trusted evidence, release authorization, and future AnoCrypto-C
hosted/authorization evidence

UPSTREAM:
AnoCrypto-C primitives, stable failure contract, test seams, approved package,
static/shared qualification, then dependent Enterprise parity/package work

DECISION:
private reporting, operational roles, support transition, and operational
systems or explicit pre-GA waiver

LATER:
richer verification UX, optional platforms, future profiles, unselected vendor
adapters, convenience features, extra links, and schema extensions
```

Every non-closed blocker appears exactly once in EXTERNAL, UPSTREAM, or
DECISION. LATER items are named optional enhancements, not hard blockers.
