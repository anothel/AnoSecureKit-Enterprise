# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Product Boundary

## Community

Bundled Community v0.4.0 is MPL-2.0 and provides the shared C++ API, common
implementation, formats, tests, and official OpenSSL provider.

## Enterprise

Enterprise-owned code is proprietary. Enterprise is a Community superset with
explicit backend profiles, product policy, diagnostics, packaging, and customer
delivery material.

Enterprise owns:

- `SKT1`, `SKF1`, `SKP1` formats and versioning;
- nonce and AAD composition;
- packet/file streaming and transaction boundaries;
- temporary files, path safety and authenticated output commit;
- backend capability reporting and no-fallback policy;
- packaging, support, provenance and release authorization.

## AnoCrypto-C

AnoCrypto-C is external MPL-2.0 software. The Enterprise AnoCrypto-C profile
consumes `AnoCryptoC::AnoCryptoC` through a proprietary provider adapter. It is
not relicensed by Enterprise. Applicable MPL source and notice obligations must
be preserved, and commercial or private-repository status does not remove them.
Legal review remains required before customer delivery; this is not legal
advice. No AnoCrypto-C source or binary is bundled here, and no KCMVP/FIPS
validation is claimed.

AnoCrypto-C owns:

- SHA-256 and HMAC-SHA-256;
- HKDF-SHA-256;
- secure random service;
- fixed-profile scrypt;
- AES-256-GCM one-shot and streaming primitives;
- in-memory CSP handles, module state and stable C ABI.

## Runtime adapter boundary

Enterprise owns the provider lifecycle/diagnostic contract and proprietary
AnoCrypto-C adapter. Community remains unaware of AnoCrypto-C. The external
module is consumed through its package target and is not copied into either
AnoSecureKit repository.

P3-06 connects the primitive layer without copying AnoSecureKit formats or
workflows into AnoCrypto-C. Exact product fixtures validate compatibility at
the adapter boundary. The OpenSSL and AnoCrypto-C profiles are compile-time
alternatives; silent or automatic cross-backend fallback is forbidden.

The exact dependency identity is defined in
[ANOCRYPTO_C_PINNED_CONTRACT.md](ANOCRYPTO_C_PINNED_CONTRACT.md). Local source
trees and archives are not approved packages merely because compatibility tests
pass.

## Installation boundary

Only the Enterprise OpenSSL profile currently has install/export rules and an
installed-consumer gate. The AnoCrypto-C build-tree parity profile installs no
customer-facing files. This prevents engineering checkpoints or metadata-only
adapters from being mistaken for a deliverable Enterprise product.
