# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Security Record Retention Policy

```text
status:
internal policy target

contractual obligation:
none defined
```

These periods are internal operating targets, not legal advice, a statutory
claim, customer SLA, warranty, or contractual retention promise. An approved
case may impose a longer period; applicable law and contract control when they
exist.

| Class | Minimum retention target | Deletion eligibility | Required approval role | Integrity verification | Migration requirement | Legal-hold override | Incident closure | Artifact withdrawal |
|---|---|---|---|---|---|---|---|---|
| `ephemeral` | 30 days after validated ingestion or test completion | After target and successful ingestion; test output may be regenerated | `evidence-custodian` | Before deletion | Move required evidence to its final class | No deletion while held | Delete only non-record working copies | Delete only unneeded working copies |
| `operational` | 1 year after incident closure or supersession | After target when no release/security dependency remains | `evidence-custodian` | Quarterly | Migrate before system retirement/format loss | Legal hold makes it non-deletable | Retain through closure plus target | Preserve if it supports withdrawal |
| `security-record` | 7 years after incident closure | After target, approved disposition, and dependency review | `incident-commander` and `evidence-custodian` | Quarterly and before migration | Preserve metadata, digest, custody, and readable format | Legal hold overrides every deletion target | Closure starts the minimum period; reopening resets review | Withdrawal does not shorten retention |
| `release-evidence` | Supported artifact lifetime plus 7 years after withdrawal/end of support, whichever is later | Only after all bound artifacts/authorizations are out of scope and target elapsed | `release-authorizer` and `evidence-custodian` | Before release, quarterly, and before migration | Preserve exact artifact/revision/digest bindings | Legal hold overrides every deletion target | Incident closure does not shorten retention | Withdrawal starts, never ends, the post-withdrawal period |
| `legal-hold` | Indefinite until written hold release, then reclassify | Never automatically; only after authorized hold release and reclassification | `incident-commander` plus separately authorized legal function | Monthly and before migration | Lossless migration with custody continuity required | This class is the override | Closure has no deletion effect | Withdrawal has no deletion effect |

Deletion means controlled disposition with an appended decision record. It
requires a final integrity check, custody update, dependency check, and proof
that no active hold applies. Silent expiry, automated legal-hold deletion, and
rewriting history are forbidden.
