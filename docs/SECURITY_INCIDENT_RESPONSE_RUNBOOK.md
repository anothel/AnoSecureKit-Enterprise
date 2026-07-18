# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Security Incident Response Runbook

This runbook applies the existing vulnerability, release-revocation, trusted
evidence, and authorization policies. The checked-in tabletop fixtures are
synthetic test inputs, not production incident records. They must not create an
advisory, CVE, customer notice, artifact deletion, release revocation, contact,
or support promise.

## Activation and intake

An actual case can begin only after verified receipt through an activated
private channel or an internally authorized security escalation. Preserve the
original technical evidence, minimize personal data, assign a private case ID,
and record who may access it. Current channel state remains:

```text
private vulnerability reporting: not yet activated
security contact: not yet published
public disclosure channel: not yet activated
```

For this tabletop, use only `tests/fixtures/security-tabletop/*.json` and the
non-personal roles in `SECURITY_OPERATIONS_ROLE_MODEL.md`.

## Incident flow

Confirmed-case path:

```text
reported -> acknowledged -> triaged -> confirmed -> mitigating -> fixed -> requalifying -> closed
```

Disposition paths:

```text
reported -> acknowledged -> triaged -> rejected
reported -> acknowledged -> triaged -> not-applicable
```

Do not close a confirmed incident before remediation and required
requalification. New evidence may reopen a rejected or not-applicable case.

At triage, the `incident-commander` records severity, affected exact revision,
profile, dependency, artifact set, evidence basis, authorization impact, and
owner. Critical/high release-path cases immediately block delivery while scope
is bounded.

## Ownership and containment

| Finding | Route | Immediate containment |
|---|---|---|
| Community OpenSSL provider/API/seam/v1 defect | `community-liaison` | Block affected Community revision; no subtree patch |
| Enterprise AnoCrypto-C adapter/status/fail-closed defect | `product-owner` | Mark partial profile not passed; no delivery |
| AnoCrypto-C primitive/API/ABI/package/digest defect | `anocrypto-c-liaison` | Mark profile unavailable; no OpenSSL fallback |
| Hosted, signing, verifier, trust-root, provenance, or attestation defect | `evidence-reviewer` | Reject affected evidence and deny/revoke authorization |
| Artifact, manifest, digest, inventory, or SBOM mismatch | `product-owner` and `evidence-reviewer` | Stop generation; quarantine affected test output |

Only the owning repository receives a source fix. Enterprise consumes an
approved new Community revision or AnoCrypto-C package, then reruns the exact
required gates.

## Release, evidence, artifact, and notification decisions

Affected qualification becomes `invalidated` or `not-passed`. Affected trusted
evidence becomes `rejected` or `unavailable`. Authorization becomes denied,
revoked, or unavailable; the repository summary remains:

```text
release_authorization: denied-or-unavailable
customer_release_ready: false
```

Actual artifact withdrawal requires a separately authorized production case
and controlled distribution inventory. Tabletop `withdraw-test-only` means
record the expected action only; it never removes an artifact. Customer notice
remains `not-sent-test-only`.

## Closure

Closure requires root cause and ownership confirmed, smallest complete fix or
safe disposition recorded, affected artifacts/evidence handled, every listed
requalification passed, fresh evidence reviewed, and a separate authorization
decision. This rehearsal deliberately ends without release authorization.
