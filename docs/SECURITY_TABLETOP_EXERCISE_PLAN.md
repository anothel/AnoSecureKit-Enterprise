# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Security Tabletop Exercise Plan

## Scope and safety boundary

Exercise scope is Enterprise-owned policy, validator, test fixtures, and local
qualification. No real report, advisory, CVE, customer message, artifact
withdrawal, release cancellation, upstream source patch, contact activation,
or support/SLA promise is permitted. All scenario revisions begin with
`test-only:` and all customer delivery targets are false.

## Scenarios

| ID | Inject | Required route and recovery |
|---|---|---|
| A | Critical Community OpenSSL provider defect | `community-liaison`; no subtree patch; consume approved Community revision; full Windows/WSL requalification |
| B | High Enterprise AnoCrypto-C adapter status/fail-closed defect | `product-owner`; block partial profile; fix adapter; Windows/WSL regression |
| C | Compromised AnoCrypto-C package digest | `anocrypto-c-liaison`; profile unavailable; no OpenSSL fallback; approved package/digest and partial-profile requalification |
| D | Revoked signing identity, verifier, or trust root | `evidence-reviewer`; reject old evidence; simulate withdrawal and authorization revocation; require new signing/provenance chain |
| E | Invalidated hosted qualification | `evidence-reviewer`; return qualification to not passed; reject attestation/evidence; rerun hosted lanes |
| F | Artifact, manifest, or SBOM digest mismatch | `product-owner`; stop package generation; quarantine synthetic partial output; regenerate and requalify artifact set |

Every confirmed path uses:

```text
reported -> acknowledged -> triaged -> confirmed -> mitigating -> fixed -> requalifying -> closed
```

Every final fixture requires:

```text
release_authorization: denied-or-unavailable
customer_release_ready: false
```

## Execution

From a clean configured build:

```sh
cmake --build build --config Release --target enterprise-security-tabletop-check
cmake --build build --config Release --target enterprise-release-preflight --parallel 4
```

The focused target validates all six records, strict fields, timestamps,
non-personal ownership, state transitions, routing, dependency boundaries,
evidence/authorization actions, requalification, no fallback, no production
use, and 20 generated negative mutations. Package verification independently
rejects any JSON carrying `test-only-security-tabletop`.

## Pass criteria

- Scenarios A-F exist once each and validate.
- Unknown/missing fields and unsafe content fail closed.
- Critical/high cases cannot allow release.
- Compromised dependencies/evidence cannot retain trusted evidence or approval.
- Community and AnoCrypto-C ownership boundaries remain intact.
- All confirmed closures include requalification.
- Installed/non-bundled consumers and ZIP/TGZ delivery contain no tabletop fixture.
- Default trusted evidence remains unavailable/rejected, authorization is denied,
  and `customer_release_ready` remains false.
