# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# AnoSecureKit Enterprise Security Release and Revocation Policy

## Fail-closed release conditions

New customer delivery and publication remain blocked when any of these applies:

- unresolved critical or high release blocker;
- an affected release artifact or unsafe supported version;
- invalidated manifest, SBOM, digest, signature, or artifact inventory;
- compromised signing identity, verifier, or trust root;
- revoked or unavailable signing/provenance/revocation evidence;
- affected Community revision or AnoCrypto-C package digest;
- expired, revoked, missing, or mismatched release authorization;
- invalidated hosted qualification or CodeQL evidence;
- attestation repository, source revision, subject, workflow, or trust-domain
  mismatch;
- pending withdrawal or affected-customer notification decision.

Policy response uses existing schema states; no speculative schema extension is
required. An affected authorization is `deny`, `revoked`, expired, or absent.
Affected trusted evidence is `rejected` or `unavailable`. Therefore:

```text
release_authorization: denied-or-unavailable
trusted_evidence: unavailable or rejected
customer_release_ready: false
```

An incident decision takes effect immediately even if a checked-in default
record has not yet been replaced. A reference string, issue, approval message,
or emergency label cannot override cryptographic verification and strict
authorization.

## Security patch and backport

Security work stays private until coordinated disclosure permits publication.
A patch branch starts from each affected supported release revision, contains
the smallest complete fix and regression check, and avoids unrelated changes.
Backport only when the version is in `supported`, `maintenance`, or
`security-fixes-only`, the vulnerability affects it, the fix preserves its
documented API/format behavior, and the branch can complete its required
qualification. Unsupported and end-of-support versions receive no backport
commitment.

Emergency priority may shorten scheduling and review queues; it never bypasses
tests, artifact verification, SBOM/manifest regeneration, hosted/CodeQL policy,
attestation, trusted evidence, release authorization, or required approvals.
If those gates cannot complete, distribute mitigation guidance through an
activated private channel and keep customer delivery blocked.

## Withdrawal, revocation, and rollback

Affected packages are withdrawn from every controlled distribution location.
Their artifact identity, digest, affected versions/configurations, reason,
replacement guidance, and decision time are recorded privately and later in an
advisory when disclosure permits. Signing/provenance evidence is marked revoked
or unavailable through its authoritative system; release authorization is
revoked or replaced by deny.

Rollback is allowed only to a qualified, unrevoked, unaffected artifact whose
dependencies and formats remain compatible with customer data. Rollback is not
safe when the older version is affected, cannot read required formats, would
reuse compromised keys/trust material, or lacks current authorization. When no
safe rollback exists, stop delivery/use and provide mitigation or a forward fix.
Customers must rerun published package checksum/signature/attestation and
deployment checks after rollback or update; no existing verification result
transfers to a different artifact.

## Dependency updates

Community OpenSSL provider, common API, generic seam, and v1 format fixes must
land in AnoSecureKit Community. Enterprise then consumes an approved Community
revision and reruns full Enterprise qualification. Enterprise does not patch
the bundled Community subtree.

AnoCrypto-C primitive, API, ABI, or package fixes must land in AnoCrypto-C.
Enterprise updates the reviewed package identity/digest, validates the pinned
contract and adapter, confirms no OpenSSL fallback, and reruns the applicable
partial/full gates. Enterprise does not patch AnoCrypto-C source.

Any dependency upgrade requires license/notice review, affected-version
analysis, compatibility tests, fresh package/artifact/SBOM/manifest evidence,
and updated source/package bindings.

## Reauthorization and disclosure

Release authorization may be reissued only for an unaffected or fixed exact
source revision after all local and hosted lanes, required CodeQL, artifacts,
SBOM/manifest, attestation, signing/provenance, revocation, trusted-evidence,
security, support, and legal approvals are fresh and mutually consistent. Old
authorization or trusted evidence is never copied forward.

Disclosure coordinates patch availability, affected versions, severity,
mitigation, upgrade/rollback guidance, artifact withdrawal, advisory/CVE
decision, and customer notification. The public disclosure channel and customer
communication channel are not yet activated; no channel or response promise is
invented by this policy. Internal delivery artifacts are not customer releases.
No KCMVP or FIPS validation is claimed.
