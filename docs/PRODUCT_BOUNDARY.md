# Product Boundary

## Community

Bundled Community v0.4.0 is MPL-2.0 and provides the shared C++ API, common
implementation, formats, tests, and official OpenSSL provider.

## Enterprise

Enterprise-owned code is proprietary. Enterprise is a Community superset with
explicit backend profiles, product policy, diagnostics, packaging, and customer
delivery material.

## AnoCrypto-C

AnoCrypto-C is external MPL-2.0 software. The Enterprise AnoCrypto-C profile
consumes `AnoCryptoC::AnoCryptoC` through a proprietary provider adapter. It is
not relicensed by Enterprise. Applicable MPL source and notice obligations must
be preserved, and commercial or private-repository status does not remove them.
Legal review remains required before customer delivery; this is not legal
advice. No AnoCrypto-C source or binary is bundled here, and no KCMVP/FIPS
validation is claimed.

## Runtime adapter boundary

Enterprise owns the provider lifecycle/diagnostic contract and the proprietary
partial AnoCrypto-C adapter. Community remains unaware of AnoCrypto-C. The external
module is consumed through its package target and is not copied into either
AnoSecureKit repository.

The exact dependency identity is defined in
[ANOCRYPTO_C_PINNED_CONTRACT.md](ANOCRYPTO_C_PINNED_CONTRACT.md). The local
AnoCrypto-C root `AnoCrypto-C.zip` is not an approved package.


## Installation boundary

Only the Enterprise OpenSSL profile currently has install/export rules and an
installed-consumer gate. The incomplete AnoCrypto-C build-tree profile installs
no customer-facing files. This prevents partial or metadata-only adapters from
being mistaken for a deliverable Enterprise product.
