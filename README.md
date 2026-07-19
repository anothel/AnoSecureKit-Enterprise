# AnoSecureKit Enterprise

AnoSecureKit Enterprise is the private/commercial superset of AnoSecureKit
Community. It keeps the Community v0.4.0 API and product formats while selecting
one explicit cryptographic backend at configure time.

## Current baseline

| Profile | Current status |
|---|---|
| `openssl` | Implementation complete; local verification passed; hosted qualification not passed / `BLOCKED_EXTERNAL`; install/export and internal ZIP/TGZ delivery enabled; customer release blocked (`customer_release_ready: false`). |
| `anocrypto-c` | P3-06 adapter and format compatibility pass locally against development revision `c101c9655f881044c14d8efbc20ea94a2e84f30b`, which reports runtime `0.1.0-p3-05-scrypt-fixed-profile`. All seven required primitive capabilities are connected, exact `SKT1`/`SKF1`/`SKP1` fixtures pass, and OpenSSL fallback/linkage is prohibited. The required reviewed source `89e16a261ab7696d9489167d7403d9f2c704629e` and digest were unavailable, so package approval, customer install/export and delivery remain blocked. |

The AnoCrypto-C parity gate is:

```text
enterprise-anocrypto-c-parity-check
```

Enterprise `0.1.0` is `unsupported` pre-release/internal qualification work,
not generally available or a production release, with no active customer
support commitment.

```text
support: unsupported pre-release/internal qualification
OpenSSL local qualification: PASS
OpenSSL hosted qualification: not passed / BLOCKED_EXTERNAL
AnoCrypto-C profile: P3-06 local compatibility; exact package/install/hosted/authorization blocked
actual operational systems: inactive
assigned operational roles: none
activation_ready: false
cryptographic evidence: unavailable
trusted evidence: unavailable
release authorization: denied-or-unavailable
customer_release_ready: false
```

Customer release additionally requires the strict
`enterprise-release-authorization-check`; the checked-in record defaults to
deny. Structural evidence contracts run through
`enterprise-trusted-release-evidence-check`; the external verifier adapter runs
through `enterprise-release-evidence-verifier-check`. No hosted attestation
exists, so cryptographic evidence remains unavailable. See
[release authorization policy](docs/RELEASE_AUTHORIZATION_POLICY.md).

This checkpoint is engineering evidence only. It is not a production release,
formal validation, signing approval, or external distribution authorization.

Pre-GA work control:

- [Blocker registry](docs/PRE_GA_BLOCKER_REGISTRY.md)
- [Development freeze and change policy](docs/DEVELOPMENT_FREEZE_AND_CHANGE_POLICY.md)
- [OpenSSL GA path](docs/OPENSSL_PROFILE_GA_PATH.md)
- [AnoCrypto-C enablement path](docs/ANOCRYPTO_C_PROFILE_ENABLEMENT_PATH.md)

Product and OpenSSL profile:

- [Product boundary](docs/PRODUCT_BOUNDARY.md)
- [Community dependency](docs/COMMUNITY_DEPENDENCY.md)
- [Backend profiles](docs/BACKEND_PROFILES.md)
- [OpenSSL profile support policy](docs/OPENSSL_PROFILE_SUPPORT_POLICY.md)
- [Supported configuration matrix](docs/SUPPORTED_CONFIGURATION_MATRIX.md)

AnoCrypto-C profile:

- [Pinned contract](docs/ANOCRYPTO_C_PINNED_CONTRACT.md)
- [Parity gaps](docs/ANOCRYPTO_C_PARITY_GAPS.md)
- [P3-06 parity checkpoint](docs/ANOCRYPTO_C_P3_06_PARITY_CHECKPOINT.md)
- [Upstream requirements](docs/ANOCRYPTO_C_UPSTREAM_REQUIREMENTS.md)
- [Integration plan](docs/ANOCRYPTO_INTEGRATION_PLAN.md)

Provider contracts:

- [Runtime contract](docs/PROVIDER_RUNTIME_CONTRACT.md)
- [Capability contract](docs/PROVIDER_CAPABILITY_CONTRACT.md)

Support and security:

- [Security policy](SECURITY.md)
- [Support lifecycle policy](docs/SUPPORT_LIFECYCLE_POLICY.md)
- [Vulnerability response policy](docs/VULNERABILITY_RESPONSE_POLICY.md)
- [Security release and revocation policy](docs/SECURITY_RELEASE_AND_REVOCATION_POLICY.md)
- [Security incident response runbook](docs/SECURITY_INCIDENT_RESPONSE_RUNBOOK.md)
- [Security operations role model](docs/SECURITY_OPERATIONS_ROLE_MODEL.md)
- [Security tabletop exercise plan](docs/SECURITY_TABLETOP_EXERCISE_PLAN.md)
- [Release revocation rehearsal](docs/RELEASE_REVOCATION_REHEARSAL.md)
- [Security tabletop result](docs/SECURITY_TABLETOP_RESULT.md)

Qualification and delivery:

- [CI and release gate](docs/CI_AND_RELEASE_GATE.md)
- [Deferred CI status](docs/DEFERRED_CI_STATUS.md)
- [Delivery verification](docs/DELIVERY_VERIFICATION.md)
- [Trusted release evidence policy](docs/TRUSTED_RELEASE_EVIDENCE_POLICY.md)
- [Release evidence verifier policy](docs/RELEASE_EVIDENCE_VERIFIER_POLICY.md)
- [Customer delivery pack](docs/CUSTOMER_DELIVERY_PACK.md)
- [Internal delivery README template](packaging/DELIVERY_README.md.in)

See [installation](docs/INSTALLATION.md), [license](LICENSE), and
[third-party notices](THIRD_PARTY_NOTICES.md) for operational use.
