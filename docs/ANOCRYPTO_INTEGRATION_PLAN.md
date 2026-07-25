# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# AnoCrypto-C Integration Plan (Archived)

```text
ACTIVE_INTEGRATION_PLAN=NONE
ACTIVE_NEXT_WORK=NONE
FUTURE_WORK=NOT_SELECTED
```

This file records the completed P3-06 engineering path. It does not authorize
additional integration, dependency changes, install/export, hosted
qualification, packaging, or release work.

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

The frozen Enterprise engineering baseline is
`dc87eae600713e482f490910233cb666b8f706b8`. P3-06 contract identity is
`89e16a261ab7696d9489167d7403d9f2c704629e`; actual Enterprise validation
used `c101c9655f881044c14d8efbc20ea94a2e84f30b`. AnoCrypto-C Phase 1 archive
`98f544a574f70b387c300f171243b4e87174937a` is retained externally, but
Enterprise revalidation against it was `NOT_RUN_AND_NOT_CLAIMED`.

The installed AnoCrypto-C config omits `find_dependency(Threads)` while
exporting `Threads::Threads`. That known limitation must be resolved before any
future install/export or customer-release reopening. It is not selected work
and does not block the current engineering freeze.

No additional primitive or future profile work is authorized by this archived
plan. Reopening requires a new product decision.
