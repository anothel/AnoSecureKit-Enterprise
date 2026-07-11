# Product Boundary

## AnoSecureKit Community

Bundled public C++20 SDK governed by MPL-2.0. Community `v0.3.0` uses OpenSSL
3.x as its production provider and remains the public API, format, test, and
compatibility baseline.

The bundled Community subtree is an unmodified verified dependency. Common
provider-seam refactoring should be contributed to the public Community
repository rather than maintained as a private patch here.

## AnoSecureKit Enterprise

Proprietary repository-owned product layer intended to cover Community
functionality and add Enterprise policy, diagnostics, packaging, deployment,
support materials, and commercial integration.

Enterprise has two intended explicit profiles:

```text
OpenSSL profile
AnoCrypto-C profile
```

The current `0.1.0` scaffold is OpenSSL-backed because it links Community's final
target. The AnoCrypto-C profile is not implemented yet.

## AnoCrypto-C

AnoCrypto-C is an external C99 cryptographic module developed, released,
licensed, and validated in its own repository. It is not bundled here.

Enterprise may contain a proprietary C++ adapter and consume a separately
provided package through:

```text
AnoCryptoC::AnoCryptoC
```

No KCMVP or FIPS validation is claimed for AnoSecureKit Enterprise or
AnoCrypto-C. Any future claim must match the exact validated module version,
configuration, operating environment, and Enterprise profile.

## Boundary Rules

- Do not commit or vendor AnoCrypto-C source, copied public headers, binaries,
  archives, or package contents in this repository.
- Do not claim KCMVP or FIPS validation before the exact integrated scope is
  validated.
- Keep MPL-2.0 notices for Community files when bundled or distributed.
- Keep Enterprise-only code outside MPL-covered Community files unless the
  change is intentionally contributed back under MPL-2.0.
- Do not call a build the AnoCrypto-C profile while it still links Community's
  OpenSSL provider or silently falls back to OpenSSL.
- Fail closed when the selected profile lacks a required provider target,
  operational state, self-test status, or capability.
