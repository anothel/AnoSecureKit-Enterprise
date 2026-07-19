# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Provider Capability Contract

The complete Enterprise product capability set is:

```text
sha256;hmac-sha256;hkdf-sha256;random;scrypt;aes256-gcm;aes256-gcm-stream
```

The selected AnoCrypto-C provider must be a non-imported CMake `OBJECT_LIBRARY`
with backend identity `anocrypto-c`, the exact list above, and a direct private
link to `AnoCryptoC::AnoCryptoC`.

Configuration fails when:

- the target does not exist or is imported;
- the target is not an `OBJECT_LIBRARY`;
- backend identity is not `anocrypto-c`;
- any required capability is missing;
- the direct AnoCrypto-C target link is absent.

P3-06 implements and verifies all seven services. Runtime readiness requires the
runtime mask to equal the same complete set after successful module lifecycle
and self-test checks.

Capability completeness is not customer release authorization. The AnoCrypto-C
profile remains excluded from installation, exports and delivery packages until
those independent gates are approved.
