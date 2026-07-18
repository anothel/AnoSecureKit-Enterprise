# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Security Tabletop Result

## Execution record

```text
execution_date: 2026-07-18
source_baseline_revision: ea3b9d0dae40a359ecdb9cde8116d152a20b5a81
exercise_scope: test-only Enterprise worktree anchored to source baseline
scenarios: A, B, C, D, E, F
```

The exact committed result revision is reported separately after this record is
committed; a file cannot contain its own Git object ID. The exercise did not
modify Community or AnoCrypto-C source.

Expected and observed confirmed-case transition:

```text
reported -> acknowledged -> triaged -> confirmed -> mitigating -> fixed -> requalifying -> closed
```

## Validator result

The tabletop validator passed all six fixtures and 20 generated negative
mutations. The linked evidence-custody validator passed six custody chains,
six decision histories, and 39 generated negative cases on Windows and WSL.

Windows clean Visual Studio 2026/MSVC Release verification passed:

- aggregate `enterprise-release-preflight`;
- full CTest `14/14`;
- support, tabletop, evidence, authorization-contract, diagnostics, installed
  consumer, ZIP/TGZ, manifest, SHA256SUMS, SPDX, downloaded-artifact, and
  Community subtree checks;
- separate installed non-bundled Community/Enterprise consumer.

WSL Ubuntu 26.04/GCC 15.2.0/Ninja Release verification passed:

- aggregate `enterprise-release-preflight`;
- full CTest `14/14`;
- support, tabletop, evidence, authorization-contract, diagnostics, installed
  consumer, ZIP/TGZ, manifest, SHA256SUMS, SPDX, downloaded-artifact, and
  Community subtree checks;
- separate installed non-bundled Community/Enterprise consumer;
- AnoCrypto-C partial profile `8/8`, including dependency purity and no
  OpenSSL fallback, under the documented development-only unknown-commit
  override with the expected commit still pinned.

Production authorization is intentionally not a passing test. The dirty
worktree check denied it before commit. After commit, the strict default
authorization-record validator returned the expected deny and
`customer_release_ready: false`; the clean customer gate rejected the stale
checked-in trusted-evidence source binding before authorization evaluation.
Both paths keep customer delivery blocked without changing either record.

## Policy gaps and changes

- Operational ownership was implicit: added non-personal roles, all still
  `not yet assigned`.
- Evidence classification, custody transfer, decision history, and retention
  were implicit: added fixed schemas, SHA-256 chains, source/size verification,
  release-block semantics, and internal retention targets.
- Incident/revocation narratives were not executable: added strict test-only
  JSON records, state-transition validation, scenario routing, and negative
  contract checks.
- Fixture/package separation was implicit: package verification now rejects
  the tabletop record marker.
- No schema v1 production format changed; no contact, SLA, support, or release
  claim was added.

## Remaining operational dependencies

Actual role assignment, evidence repository, incident tracker, long-term
archive, private reporting/contact activation, hosted runner completion,
CodeQL, attestation, signing/provenance verification, trusted evidence,
legal/support approval, and release authorization remain external and
unavailable. Hosted run `29624647348` remains `BLOCKED_EXTERNAL`.

```text
private vulnerability reporting: not yet activated
security contact: not yet published
public disclosure channel: not yet activated
approved evidence repository: not yet activated
approved incident tracking system: not yet activated
approved long-term archive: not yet activated
release_authorization: denied-or-unavailable
customer_release_ready: false
```

No customer data, personal assignee, notification, artifact withdrawal, release
revocation, advisory, or CVE was created.
