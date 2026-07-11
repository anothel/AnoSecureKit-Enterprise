# Product Boundary

## AnoSecureKit Community

Bundled public C++20 SDK governed by MPL-2.0. It uses OpenSSL 3.x as its current
production backend and remains the open compatibility and trust base.

## AnoSecureKit Enterprise

Proprietary repository-owned SDK layer. Enterprise owns its wrapper, customer
packaging, deployment policy, support materials, and commercial integration.

## AnoCrypto Core

Optional external cryptographic dependency. AnoCrypto is not included in this
repository and, when supplied, remains governed by separate commercial terms.
No KCMVP or FIPS validation is claimed for AnoSecureKit Enterprise or AnoCrypto.

## Boundary Rules

- Do not commit or vendor AnoCrypto source, headers, binaries, or packages in
  this repository.
- Do not claim KCMVP or FIPS validation before validation exists.
- Keep MPL-2.0 notices for Community files when vendored into Enterprise.
- Keep Enterprise-only code outside MPL-covered Community files unless you are
  intentionally contributing those modifications back under MPL-2.0.
