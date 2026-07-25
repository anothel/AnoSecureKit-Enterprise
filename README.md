# AnoSecureKit Enterprise

AnoSecureKit Enterprise is the private Enterprise superset of AnoSecureKit
Community. It keeps the Community v0.4.0 API and product formats while selecting
one explicit cryptographic backend at configure time.

The canonical current-state record is
[docs/CURRENT_STATUS.md](docs/CURRENT_STATUS.md).

## Frozen engineering baseline

| Profile | Current status |
|---|---|
| `openssl` | Engineering implementation and local qualification complete against exact Community `v0.4.0`; install/export and internal delivery enabled; hosted qualification not run; customer release blocked. |
| `anocrypto-c` | Seven-capability adapter, exact `SKT1`/`SKF1`/`SKP1` fixture compatibility, fail-closed behavior, and no-fallback behavior recorded PASS against `c101c9655f881044c14d8efbc20ea94a2e84f30b`; install/export and customer delivery disabled. |

The AnoCrypto-C parity gate is:

```text
enterprise-anocrypto-c-parity-check
```

Enterprise `0.1.0` is closed and frozen at engineering baseline
`dc87eae600713e482f490910233cb666b8f706b8`. It remains unsupported
pre-release/internal qualification work, not generally available or a
production release, with no active customer support commitment.

```text
support: unsupported pre-release/internal qualification
OpenSSL local qualification: PASS
OpenSSL hosted qualification: NOT_RUN
AnoCrypto-C profile: c101c965 local compatibility; Phase 1 final revalidation NOT_RUN_AND_NOT_CLAIMED
actual operational systems: inactive
assigned operational roles: none
activation_ready: false
cryptographic evidence: unavailable
trusted evidence: unavailable
release authorization: denied-or-unavailable
customer_release_ready: false
active_next_work: none
active_release_action: none
```

Customer release additionally requires the strict
`enterprise-release-authorization-check`; the checked-in record defaults to
deny. Structural evidence contracts run through
`enterprise-trusted-release-evidence-check`; the external verifier adapter runs
through `enterprise-release-evidence-verifier-check`. No hosted attestation
exists, so cryptographic evidence remains unavailable. See
[release authorization policy](docs/RELEASE_AUTHORIZATION_POLICY.md).

This closeout is engineering evidence only. It is not a production release,
formal validation, signing approval, or external distribution authorization.

Closeout and retained pre-GA records:

- [Canonical current status](docs/CURRENT_STATUS.md)
- [Blocker registry](docs/PRE_GA_BLOCKER_REGISTRY.md)
- [Development freeze and change policy](docs/DEVELOPMENT_FREEZE_AND_CHANGE_POLICY.md)
- [Archived OpenSSL GA gate record](docs/OPENSSL_PROFILE_GA_PATH.md)
- [Archived AnoCrypto-C enablement path](docs/ANOCRYPTO_C_PROFILE_ENABLEMENT_PATH.md)

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
- [Archived integration plan](docs/ANOCRYPTO_INTEGRATION_PLAN.md)

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
