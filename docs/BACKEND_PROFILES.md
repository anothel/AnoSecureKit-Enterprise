# Enterprise Backend Profiles

AnoSecureKit Enterprise is a superset product assembled from Community v0.4.0
and an explicit cryptographic backend profile.

## OpenSSL profile

```text
-DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl
```

This is the current working profile. It uses Community's official OpenSSL
provider and adds the Enterprise layer.

## AnoCrypto-C profile

```text
-DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=anocrypto-c
```

This profile requires:

- an external `AnoCryptoC` package;
- imported target `AnoCryptoC::AnoCryptoC`;
- a non-imported Enterprise `OBJECT_LIBRARY` provider adapter implementing the
  complete Community provider contract;
- all capabilities required by the selected product surface.

The profile fails configuration when any requirement is missing. It never falls
back to OpenSSL. The current repository does not yet contain the complete
AnoCrypto-C provider adapter, so this profile is intentionally not buildable as
a production product yet.
