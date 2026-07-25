# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# AnoSecureKit Enterprise Current Status

This is the canonical current-state document for Enterprise `0.1.0`. Historical
plans, checkpoints, registries, authorization records, packages, manifests, and
checksums remain evidence only and do not override this document.

## Canonical closeout state

```text
PROJECT=AnoSecureKit-Enterprise
PRODUCT_VERSION=0.1.0
LIFECYCLE=UNSUPPORTED_PRE_RELEASE_INTERNAL_QUALIFICATION

ENGINEERING_STATUS=CLOSED_AND_FROZEN
ENTERPRISE_ENGINEERING_BASELINE=dc87eae600713e482f490910233cb666b8f706b8
FINAL_CLOSEOUT_COMMIT=RECORDED_IN_EXTERNAL_CLOSEOUT_EVIDENCE

COMMUNITY_PUBLIC_BASELINE=v0.4.0@694459ebe497d15ba75ef76a52fa7c36ddd7bcce
COMMUNITY_SUBTREE_RELATION=EXACT
ACTIVE_BLOCKER_COUNT=0
ACTIVE_NEXT_WORK=NONE
ACTIVE_RELEASE_ACTION=NONE
FUTURE_WORK=NOT_SELECTED

CUSTOMER_RELEASE=BLOCKED
CUSTOMER_RELEASE_READY=FALSE
COMMERCIALIZATION=UNDECIDED
TAG=NONE
GITHUB_RELEASE=NONE
KCMVP=NOT_VALIDATED
FIPS=NOT_VALIDATED
EXTERNAL_SECURITY_AUDIT=NOT_RUN
REPOSITORY_ARCHIVED=FALSE
REOPEN_REQUIRES_NEW_PRODUCT_DECISION
```

The final documentation commit cannot contain its own Git object ID. Its exact
commit is therefore recorded in external closeout evidence after the
user-owned commit is created. This does not authorize a tag, GitHub Release,
package, customer release, commercialization, or repository archive action.

## Engineering and historical checkpoints

| Record | Identity | Disposition |
|---|---|---|
| Enterprise engineering baseline | `dc87eae600713e482f490910233cb666b8f706b8` | Actual complete engineering baseline |
| Historical external checkpoint | `53824f00ff3460ba05ac866d1dd58d9a0c01ff3c` | Historical external evidence only |
| Current repository successor | `dc87eae600713e482f490910233cb666b8f706b8` | Replaces the historical checkpoint as the engineering baseline |

## Community dependency

```text
COMMUNITY_RELEASE_COMMIT=694459ebe497d15ba75ef76a52fa7c36ddd7bcce
COMMUNITY_ROOT_TREE=5478a5c37e96aa1017f8f4604234de48c1115d7c
ENTERPRISE_SUBTREE_TREE=5478a5c37e96aa1017f8f4604234de48c1115d7c
COMMUNITY_SUBTREE_RELATION=EXACT
```

Enterprise contains the exact public Community `v0.4.0` tree. Community final
closeout commit `298bcbd125cafae26cf54a6ec81c98b7f729b477`, unpublished
maintenance `0.4.1` (`df1936777843415022a97f775c6e61eea6d99cb0`), and parked
feature branch `develop/v0.5.0@9fe79dc1e0f8b9951e86c2707c70469611ab43e4`
are not included.

## AnoCrypto-C dependency identities

These identities have different purposes and are not interchangeable.

| Record | Commit / runtime | Artifact identity | Disposition |
|---|---|---|---|
| P3-06 contract | `89e16a261ab7696d9489167d7403d9f2c704629e` / `0.1.0-p3-05-scrypt-fixed-profile` | Source SHA-256 `18aa9050a808e4d541b2a6a10e91aa8e51367b95962b90db2183e26377bdbac1` | Pinned reviewed contract |
| Actual Enterprise validation | `c101c9655f881044c14d8efbc20ea94a2e84f30b` / `0.1.0-p3-05-scrypt-fixed-profile` | Windows DLL SHA-256 `051bcef36d99c43398e114198880645b3505bfcc3dad99217bfb10ebd7308c5d` | Recorded Windows and WSL parity validation |
| AnoCrypto-C Phase 1 archive | `98f544a574f70b387c300f171243b4e87174937a` / `0.1.0-p3-10-restricted-sha1-ocsp-certid` | Source ZIP SHA-256 `913979ceea9110de5dbfe9e6702c634071102b00901840763367ca83e15d59c4`; DLL SHA-256 `7dd56b00f38699509e90a62968ec0ff2c37a2735e4479c0df4a2c60f8b2e26cd` | External final Phase 1 archive |

```text
ANOCRYPTO_C_PHASE1_FINAL_RERUN=NOT_RUN_AND_NOT_CLAIMED
```

Enterprise was not revalidated against `98f544a...`. That commit is not the
Enterprise pin or validation baseline, and no result against it is claimed.

## Profile state

### OpenSSL

```text
IMPLEMENTATION=COMPLETE
DEFAULT_BACKEND=OPENSSL
COMMUNITY_DEPENDENCY=EXACT_V0_4_0
INSTALL_EXPORT=ENABLED
INTERNAL_DELIVERY=ENABLED
CUSTOMER_RELEASE=BLOCKED
```

Local Windows Release build, CTest, aggregate preflight, exact Community/API and
format compatibility, installed consumer, non-bundled consumer, backend
boundary, manifest, SBOM, and source-offer structure checks have recorded PASS
evidence. Hosted qualification was not run for the integration or closeout
revision.

### AnoCrypto-C

```text
SEVEN_CAPABILITIES=IMPLEMENTED
FORMAT_FIXTURE_PARITY=RECORDED_PASS
NO_FALLBACK=RECORDED_PASS
INSTALL_EXPORT=DISABLED
PACKAGE_DELIVERY=FAIL_CLOSED
CUSTOMER_RELEASE=BLOCKED
P3_10_REVALIDATION=NOT_RUN_AND_NOT_CLAIMED
```

The recorded `c101c965...` validation covers SHA-256, HMAC-SHA-256,
HKDF-SHA-256, random, fixed-profile scrypt, AES-256-GCM one-shot, and
AES-256-GCM streaming. Exact `SKT1`, `SKF1`, and `SKP1` fixtures,
wrong-key/wrong-password no-output behavior, missing-service failure, no
OpenSSL fallback, and Linux dependency purity have recorded PASS evidence.

## Historical source-offer disposition

```text
PATH=src/internal/secure_wipe.hpp
CAUSE=LF_VS_CRLF_LINE_ENDING_TRANSFORMATION

CURRENT_COMMUNITY_V0_4_0_TREE=EXACT
CURRENT_ENTERPRISE_SUBTREE=EXACT
HISTORICAL_SOURCE_OFFER=ARCHIVE_ONLY_NON_CANONICAL
HISTORICAL_SOURCE_OFFER_BYTE_EXACT_CLAIM=INVALID
HISTORICAL_ARTIFACT_REPAIR=NOT_SELECTED
HISTORICAL_ARTIFACT_REPUBLICATION=NOT_AUTHORIZED
CLOSEOUT_BLOCKER=NO
```

Mismatch evidence:

- current exact-tree file SHA-256:
  `a38ec0033c027c501b7dc75da37a89283bae2aafc791434868cccae9f71fc651`;
- archived source-offer file SHA-256:
  `cacb460f19926a82538c9f64a9527bcc5c024708cbfd2d463c85a49fa77ff0e2`;
- current Git blob:
  `a3bd8ae8724f47a74796df53dc6e14d4561c4088`;
- archived CRLF blob:
  `3234df171e2ddae5e17967399639208af4e7ccba`;
- archived source-offer ZIP SHA-256:
  `d69379e16a306c3bdfdee15366c3ebbb92e71c415444b68cc4892aae1d40c885`.

The historical ZIP, checksum, manifest, original SHA-256 values, and mismatch
evidence must remain unchanged. They are not canonical exact-source evidence
and not customer-release evidence. The validator remains strict; no exception
or compatibility waiver is added. No historical package is repaired,
regenerated, replaced, or republished.

If separately authorized after the final Git closeout commit exists, the final
closeout source ZIP must be generated from that exact commit tree. No such
package is generated or authorized by this closeout documentation.

## Known limitations and reopen gates

- AnoCrypto-C's installed CMake config exports `Threads::Threads` without
  `find_dependency(Threads)`. This is
  `KNOWN_LIMITATION_NOT_SELECTED`: it does not block the current engineering
  freeze, but must be resolved before install/export or customer release is
  reconsidered.
- Public Community `v0.4.0` can create generic CLI key/plaintext output with
  POSIX mode `0644` under `umask 022`. Enterprise inherits that exact public
  baseline limitation. The unpublished `0.4.1` fix is not included.
- Hosted CI, CodeQL, signing, provenance, attestation, KCMVP, FIPS, and external
  security audit evidence do not exist for the final closeout state.

These are archived limitations or conditional reopen gates, not active work.
Resolving or selecting any of them requires a new product decision.

## Hosted and release boundary

```text
INTEGRATION_HOSTED_CI=NOT_RUN
FINAL_CLOSEOUT_HOSTED_CI=NOT_RUN
CODEQL=NOT_RUN
HOSTED_ARTIFACT_SET=NONE
SIGNING=UNAVAILABLE
PROVENANCE=UNAVAILABLE
ATTESTATION=NOT_GENERATED
CUSTOMER_RELEASE_AUTHORIZATION=DENY_INACTIVE_HISTORICAL
```

The failed hosted record for `main@a15f10f...` is not an integration or final
closeout result. Workflow configuration for OIDC or attestation is not
execution evidence.

## Evidence retention

Retain unchanged:

- `docs/ANOCRYPTO_C_P3_06_PARITY_CHECKPOINT.md`;
- `docs/SUPPORTED_CONFIGURATION_MATRIX.md`;
- `docs/DEFERRED_CI_STATUS.md`;
- `release/customer-release-authorization.json`;
- `release/customer-release-evidence.json`;
- P3-06 recovery manifests, checksums, validation binaries, and logs;
- the AnoCrypto-C Phase 1 archive; and
- the historical source-offer ZIP/checksum/manifest, original SHA-256 values,
  and mismatch evidence.

Historical records must not be promoted to current authorization, canonical
source evidence, or customer-release evidence.
