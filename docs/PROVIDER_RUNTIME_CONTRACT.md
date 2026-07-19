# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Enterprise Provider Runtime Contract

The provider runtime contract selects exactly one compile-time backend lifecycle
adapter. Runtime plugins and automatic fallback are not supported.

Contract version `1` exposes initialize, shutdown and snapshot operations. The
snapshot reports backend name, module version, build identity, runtime status,
module state, self-test status and capability mask.

## Readiness

The AnoCrypto-C profile is ready only when:

- native initialization succeeds;
- startup self-test reports passed;
- module state is operational;
- runtime and reviewed commit identity match configuration;
- the complete seven-capability mask is present;
- the function table and contract version are valid.

Every failure is fail-closed. No runtime path falls back to OpenSSL.

## P3-06 implementation

The production adapter uses the installed public AnoCrypto-C API for:

- lifecycle and identity;
- SHA-256 and HMAC-SHA-256;
- random generation;
- HKDF-SHA-256;
- fixed-profile scrypt;
- AES-256-GCM one-shot;
- AES-256-GCM streaming.

The adapter reports all seven capabilities only because all seven implementations
and exact product compatibility tests are present. Native operation errors are
mapped separately from lifecycle errors; authentication failure is preserved.
Unknown native values fail closed as internal errors.

The build-tree profile, provider objects and private runtime headers remain
excluded from customer installation and package exports.
