# Product Boundary

## Community

Bundled Community v0.4.0 is MPL-2.0 and provides the shared C++ API, common
implementation, formats, tests, and official OpenSSL provider.

## Enterprise

Enterprise-owned code is proprietary. Enterprise is a Community superset with
explicit backend profiles, product policy, diagnostics, packaging, and customer
delivery material.

## AnoCrypto-C

AnoCrypto-C is external and separately licensed. The Enterprise AnoCrypto-C
profile consumes `AnoCryptoC::AnoCryptoC` through a proprietary provider adapter.
No AnoCrypto-C source or binary is bundled here, and no KCMVP/FIPS validation is
claimed.

## Runtime adapter boundary

Enterprise owns the provider lifecycle/diagnostic contract and the future
AnoCrypto-C adapter. Community remains unaware of AnoCrypto-C. The external
module is consumed through its package target and is not copied into either
AnoSecureKit repository.
