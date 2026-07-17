# AnoSecureKit Enterprise Trusted Release Evidence Policy

Customer release requires a separately supplied, canonical trusted-evidence
record. The repository default is `release/customer-release-evidence.json`.
It records the latest hosted run but is intentionally unavailable for trust:
hosted runners were not assigned, CodeQL did not run, artifacts were not
produced, and signing, provenance, and revocation verification are unavailable.

## Verification boundary

`cmake/check_trusted_release_evidence.cmake` implements strict structural
verification. It does not implement cryptographic verification. Neither the
Enterprise API nor the pinned Community v0.4.0 public API exposes a release
signature-verification primitive. The Community `verify-file` operation checks
the authentication of the Community encrypted-file format; it is not a release
signature verifier. Enterprise-owned code must not link OpenSSL directly,
implement custom signature cryptography, or treat a reference string as proof.

GitHub CLI 2.95.0 on the audited Windows host exposes
`gh attestation verify`, but the audited WSL GitHub CLI 2.46.0 does not, and the
Enterprise workflow does not generate GitHub attestations. No pinned,
cross-platform CLI contract, approved trusted-root policy, or real Enterprise
attestation bundle therefore exists. A locally installed external command alone
is not treated as a product cryptographic verification path.

The current boundary is therefore:

```text
structural_verifier: implemented
cryptographic_verifier: unavailable
trusted_evidence_status: unavailable or rejected
production authorization: denied
customer_release_ready: false
```

## Canonical schema version 1

Every object rejects missing and unknown members. Arrays reject duplicate
identities and have a policy-defined order. The complete document is one
minified JSON object followed by one newline. CRLF is normalized only for
cross-platform checkout; the canonical digest is SHA-256 of the LF form.
Reordered members, alternate whitespace, duplicate keys, and non-canonical data
are rejected.

Required root members are:

| Member | Contract |
|---|---|
| `schema_version`, `product` | Exact `1` and `AnoSecureKit Enterprise`. |
| `enterprise_version`, `community_version` | Exact build bindings. |
| `community_tree`, `source_revision` | Exact full lowercase Git SHAs. |
| `backend_profile`, `provider_family` | Exact `openssl` / `openssl`; partial AnoCrypto-C and fallback identities are rejected. |
| `generated_at`, `expires_at` | UTC `YYYY-MM-DDTHH:MM:SSZ`; future, expired, and invalid intervals are rejected. |
| `hosted` | Exact workflow identity, run, event, source SHA, overall status, required lanes, and lane results. |
| `codeql` | Required flag, status, and public analysis reference. CodeQL is mandatory. |
| `artifacts` | Staged manifest digest, complete artifact-set digest, and sorted file name/size/SHA-256 inventory. |
| `sbom` | Exact `SPDX-2.3` format and digest. |
| `signing` | Status, known scheme, policy identity, and public signature reference. |
| `provenance` | Status, SLSA predicate type, statement digest, and public statement reference. |
| `revocation` | `clear`, `revoked`, or `unavailable`, plus a public reference when known. |

The required hosted lanes are the five OpenSSL build-matrix lanes plus
`downloaded-artifact-validation`, `CodeQL C/C++`, the sanitizer lane, and
`non-bundled-consumer`. A passed lane must have an assigned runner and the exact
source revision. Missing, `runner-not-assigned`, `skipped`, `deferred`,
`blocked-external`, failed, or cancelled lanes never count as passed. Required
CodeQL must be `passed`.

Artifact names are normalized top-level names. Empty names, path separators,
path traversal, absolute Windows or POSIX paths, duplicate names, secret-like
names, private-key material, size mismatches, and SHA-256 mismatches are
rejected. `manifest_digest` binds the staged `MANIFEST.sha256`.
`artifact_set_digest` binds top-level `SHA256SUMS.txt`, and `files` must match
the complete delivery directory. `sbom.digest` binds its sole SPDX JSON file.

Signing schema version 1 recognizes only the Sigstore identity
`github-oidc:anothel/AnoSecureKit-Enterprise`. Recognition is structural, not
cryptographic trust. Verified signing and provenance fields still produce
`cryptographic_verifier: unavailable` until an approved public verification
API or tool, trust policy, and revocation process exist. No production trust
root or private material is stored in this repository.

## State model and authorization binding

The verifier exposes independent states:

- structural: `valid`, `invalid`, or `unavailable`;
- cryptographic: `verified`, `rejected`, or `unavailable`;
- trusted: `verified`, `rejected`, or `unavailable`.

`trusted=verified` requires every exact binding, every hosted lane, required
CodeQL, complete artifact/manifest/SBOM evidence, cryptographically verified
signing and provenance, an unexpired interval, and clear revocation. The current
implementation cannot produce `cryptographic=verified`, so it cannot produce
`trusted=verified`.

The authorization record contains `trusted_evidence_digest`, the canonical
evidence digest. The customer gate verifies delivery files first, verifies the
evidence record against the exact build and artifacts, then compares this digest
while validating authorization. Any mismatch fails before customer release.

## Commands and test-fixture isolation

```sh
cmake --build build --target enterprise-trusted-release-evidence-check
cmake --build build --target enterprise-release-authorization-check
cmake --build build --target enterprise-customer-delivery-check
```

Contract fixtures are generated only below the build test directory. They hold
no production trust root or secret and can exercise structural states only.
Production gates set `ALLOW_TEST_FIXTURE=OFF`; test mode cannot enable signing,
authorization, package publication, or customer readiness.
