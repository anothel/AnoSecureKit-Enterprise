# Enterprise Backend Profiles

AnoSecureKit Enterprise is a superset product assembled from Community v0.4.0
and an explicit cryptographic backend profile.

## OpenSSL profile

```text
-DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl
```

This working profile uses Community's official OpenSSL provider and adds the
Enterprise layer. Its built-in runtime implementation reports the Community
v0.4.0 provider identity, operational state, and full product capability mask.
It is currently the only installable/exported Enterprise delivery profile and
is verified with an independent `find_package()` consumer.

## AnoCrypto-C profile

```text
-DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=anocrypto-c
```

This profile requires:

- an external exact-version `AnoCryptoC 0.1.0` package with approved digest and
  runtime identity `0.1.0-p1-33-release-rehearsal`;
- imported target `AnoCryptoC::AnoCryptoC`;
- a non-imported Enterprise cryptographic provider `OBJECT_LIBRARY`;
- the built-in proprietary Enterprise lifecycle/diagnostic adapter;
- complete static and runtime capabilities required by the selected product
  surface.

The profile fails configuration or runtime readiness when any requirement is
missing. It never falls back to OpenSSL. The real native lifecycle adapter is
connected and identity-pinned, but no cryptographic service adapter is
connected and its runtime capability mask remains zero, so this profile is not
production-ready.
It intentionally produces no install/export or customer-delivery package.

## Production capability gate

The AnoCrypto-C profile requires the full Community v1 primitive surface:

```text
sha256
hmac-sha256
hkdf-sha256
random
scrypt
aes256-gcm
aes256-gcm-stream
```

The cryptographic provider declares static capabilities through
`ANOSECUREKIT_ENTERPRISE_PROVIDER_CAPABILITIES`. The runtime adapter reports an
independent capability mask after module initialization and self-test. Both must
cover the complete product requirement.

## Runtime readiness gate

Runtime contract version `1` requires:

- initialization result;
- shutdown;
- runtime/module status;
- self-test status;
- module version;
- build identity;
- runtime capability mask.

AnoCrypto-C readiness requires `ready`, `operational`, `passed`, and the complete
capability mask. See [PROVIDER_RUNTIME_CONTRACT.md](PROVIDER_RUNTIME_CONTRACT.md).
The dependency identity and verified capability gaps are recorded in
[ANOCRYPTO_C_PINNED_CONTRACT.md](ANOCRYPTO_C_PINNED_CONTRACT.md).
