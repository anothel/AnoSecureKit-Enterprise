# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# AnoCrypto-C Profile Enablement Path

This is a future-profile path, separate from OpenSSL GA. Current product policy
does not require both profiles to become GA together. The profile remains
`partial`, non-installable, non-exportable, and customer-blocked.

| Step | Required evidence | Responsible owner | Registry blocker |
|---|---|---|---|
| 1. Approved upstream package | approved upstream release and source identity | `anocrypto-c-liaison` | `PGA-ANO-APPROVED-PACKAGE-DIGEST` |
| 2. Exact version and digest | version, commit, package SHA-256, ABI, license binding | `anocrypto-c-liaison` | `PGA-ANO-APPROVED-PACKAGE-DIGEST` |
| 3. Capability/status/failure contract | stable API/version, lifecycle, capability, status, error, and clearing semantics | `anocrypto-c-liaison` | `PGA-ANO-CAPABILITY-STATUS-FAILURE-CONTRACT` |
| 4. HKDF | approved API plus RFC 5869 and SKF1 parity | `anocrypto-c-liaison` | `PGA-ANO-HKDF-SHA256` |
| 5. scrypt | approved bounded API plus SKP1 parity | `anocrypto-c-liaison` | `PGA-ANO-SCRYPT` |
| 6. AES-GCM | approved one-shot API plus SKF1/SKP1 parity | `anocrypto-c-liaison` | `PGA-ANO-AES256-GCM` |
| 7. Streaming AEAD | approved incremental API plus SKT1 state/failure parity | `anocrypto-c-liaison` | `PGA-ANO-STREAMING-AEAD` |
| 8. Test failure seams | deterministic test-only upstream hooks | `anocrypto-c-liaison` | `PGA-ANO-FORCED-FAILURE-SEAMS` |
| 9. Enterprise adapter parity | complete required mask, v1 bytes, state, errors, and output clearing | `product-owner` | `PGA-ANO-ENTERPRISE-ADAPTER-PARITY` |
| 10. No-fallback validation | binary dependency inspection proving no OpenSSL link/call | `product-owner` | `PGA-ANO-ENTERPRISE-ADAPTER-PARITY` |
| 11. Static/shared consumption | build/install/import/runtime/dependency tests for both package forms | `anocrypto-c-liaison` | `PGA-ANO-STATIC-PACKAGE`, `PGA-ANO-SHARED-PACKAGE` |
| 12. Install/package qualification | Enterprise install/export/CPack and independent consumer verification | `product-owner` | `PGA-ANO-INSTALL-EXPORT-CPACK` |
| 13. Hosted qualification | complete platform/package matrix at one exact revision | `product-owner` | `PGA-ANO-HOSTED-QUALIFICATION` |
| 14. Authorization | trusted evidence and separate exact profile/artifact authorization | `release-authorizer` | `PGA-ANO-CUSTOMER-AUTHORIZATION` |

Steps are ordered gates, not permission to modify AnoCrypto-C source from this
repository. Upstream primitives stay upstream; Enterprise implements adapters
only after an approved package exists. No OpenSSL fallback and no v1 change.

Current focused local profile tests prove lifecycle, SHA-256, HMAC-SHA-256,
random, status mapping, dependency purity, and fail-closed partial behavior.
They do not close any missing primitive, package, hosted, or authorization
blocker.
