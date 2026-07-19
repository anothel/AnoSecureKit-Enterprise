# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# AnoCrypto-C Integration Plan

## Adapter work completed through P3-06

1. Pin exact installed AnoCrypto-C identity and fail on mismatch.
2. Preserve lifecycle, startup self-test and status mapping.
3. Connect SHA-256, HMAC-SHA-256 and random.
4. Connect HKDF-SHA-256.
5. Connect AES-256-GCM one-shot and streaming.
6. Connect the fixed `SKP1` v1 scrypt profile with a bounded caller workspace.
7. Advertise all seven capabilities only after implementation.
8. Verify exact `SKT1`/`SKF1`/`SKP1` fixtures and product round trips.
9. Reject OpenSSL linkage or fallback in the AnoCrypto-C profile.
10. Keep customer installation and release authorization closed.

## Next work

P3-06 is a parity checkpoint, not a release. The next work belongs to product
qualification and governance:

- resolve or externally confirm remaining source-provenance records;
- run hosted platform lanes when billing/authorization allows;
- review Windows and macOS dependency inspection;
- define trusted signing/attestation intake;
- obtain explicit customer release authorization;
- only then design an install/export profile for AnoCrypto-C.

No additional primitive is authorized by this plan.

Local compatibility evidence currently comes from unapproved development
revision `c101c9655f881044c14d8efbc20ea94a2e84f30b`. The pinned reviewed revision
and source digest remain unavailable, and the development package's Linux CMake
config does not load its exported `Threads::Threads` dependency. Exact package
and install qualification therefore remain open.
