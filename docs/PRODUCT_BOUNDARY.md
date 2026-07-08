# Product Boundary

## AnoSecureKit Community

Public MPL-2.0 C++20 SDK using OpenSSL 3.x as the public production backend.
Community remains the open compatibility and trust base.

## AnoSecureKit Enterprise

Private/commercial SDK layer. Enterprise owns customer packaging, deployment
policy, support materials, commercial integration, and AnoCrypto backend wiring.

## AnoCrypto Core

Private/commercial C99 cryptographic module. AnoCrypto is the intended core
commercial asset and KCMVP-oriented backend, but it is not included in this
scaffold.

## Boundary Rules

- Do not commit AnoCrypto proprietary source into Community.
- Do not claim KCMVP validation before validation exists.
- Keep MPL-2.0 notices for Community files when vendored into Enterprise.
- Keep Enterprise-only code outside MPL-covered Community files unless you are
  intentionally contributing those modifications back under MPL-2.0.
