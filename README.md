# AnoSecureKit Enterprise

AnoSecureKit Enterprise is the private/commercial superset of AnoSecureKit
Community. It uses Community v0.4.0 as the common C++ API and implementation
baseline and selects one explicit cryptographic backend profile.

## Current baseline

| Profile | Current status |
|---|---|
| `openssl` | Implementation complete; local verification passed; remote verification deferred; install/export and internal ZIP/TGZ delivery enabled; customer release blocked (`customer_release_ready: false`). |
| `anocrypto-c` | Development/partial; lifecycle, self-test/state/identity, native status mapping, SHA-256, HMAC-SHA-256, and random connected; exact capability mask `sha256 hmac-sha256 random`; complete readiness, install/export, CPack, and customer delivery blocked; OpenSSL fallback absent. |

The bundled OpenSSL aggregate gate is `enterprise-release-preflight`. The
opt-in AnoCrypto-C development gate is
`enterprise-anocrypto-c-partial-profile-check`. Generated ZIP/TGZ files are
internal qualification artifacts, not customer releases.

## Authoritative contracts

Product and OpenSSL profile:

- [Product boundary](docs/PRODUCT_BOUNDARY.md)
- [Community dependency](docs/COMMUNITY_DEPENDENCY.md)
- [Backend profiles](docs/BACKEND_PROFILES.md)
- [OpenSSL profile support policy](docs/OPENSSL_PROFILE_SUPPORT_POLICY.md)
- [Supported configuration matrix](docs/SUPPORTED_CONFIGURATION_MATRIX.md)

AnoCrypto-C profile:

- [Pinned contract](docs/ANOCRYPTO_C_PINNED_CONTRACT.md)
- [Parity gaps](docs/ANOCRYPTO_C_PARITY_GAPS.md)
- [Upstream requirements](docs/ANOCRYPTO_C_UPSTREAM_REQUIREMENTS.md)
- [Integration plan](docs/ANOCRYPTO_INTEGRATION_PLAN.md)

Provider contracts:

- [Runtime contract](docs/PROVIDER_RUNTIME_CONTRACT.md)
- [Capability contract](docs/PROVIDER_CAPABILITY_CONTRACT.md)

Qualification and delivery:

- [CI and release gate](docs/CI_AND_RELEASE_GATE.md)
- [Deferred CI status](docs/DEFERRED_CI_STATUS.md)
- [Delivery verification](docs/DELIVERY_VERIFICATION.md)
- [Customer delivery pack](docs/CUSTOMER_DELIVERY_PACK.md)
- [Internal delivery README template](packaging/DELIVERY_README.md.in)

See [installation](docs/INSTALLATION.md), [license](LICENSE), and
[third-party notices](THIRD_PARTY_NOTICES.md) for operational use.
