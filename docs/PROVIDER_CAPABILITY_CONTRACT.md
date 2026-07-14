# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Enterprise Provider Capability Contract

AnoSecureKit Enterprise treats backend selection as a product profile, not as a best-effort runtime preference.

## Required production capabilities

The AnoCrypto-C production profile must provide the complete Community v1 primitive surface:

```text
sha256
hmac-sha256
hkdf-sha256
random
scrypt
aes256-gcm
aes256-gcm-stream
```

The list covers the primitives required by the current Community public API and the `SKT1`, `SKF1`, and `SKP1` formats. It does not assert that the external AnoCrypto-C package currently implements every item.

## Provider target metadata

The proprietary provider adapter must be a non-imported CMake `OBJECT_LIBRARY` and set:

```cmake
set_property(TARGET <provider> PROPERTY
  ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID "anocrypto-c")
set_property(TARGET <provider> PROPERTY
  ANOSECUREKIT_ENTERPRISE_PROVIDER_CAPABILITIES
  "sha256;hmac-sha256;hkdf-sha256;random;scrypt;aes256-gcm;aes256-gcm-stream")
target_link_libraries(<provider> PRIVATE AnoCryptoC::AnoCryptoC)
```

Configuration fails when the identity, capability list, direct module link, target type, or module package contract is missing.

## Fail-closed rule

A partial AnoCrypto-C provider is not promoted to the production profile. Missing services are not sent to OpenSSL and are not represented as available. Development work may implement capabilities incrementally, but production profile configuration remains blocked until the complete requirement set is met.

## Runtime gate still required

The static CMake capability declaration is only the first gate. A later implementation must also verify:

- AnoCrypto-C module initialization;
- startup self-test result;
- operational state;
- runtime module version and build identity;
- service availability reported by the module;
- error/status translation;
- absence of OpenSSL production linkage in the AnoCrypto-C profile.

Static metadata must not be treated as KCMVP or FIPS validation evidence.
