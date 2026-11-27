# AnoSecureKit Enterprise Release Evidence Verifier Policy

Customer release requires cryptographic verification by an approved external
verifier. The only production backend is `github-cli-attestation`; `none`
means no verifier was selected. Enterprise code does not implement signature
algorithms, call OpenSSL directly, download verifier binaries, or commit them.

## Tool selection and capability

Executable discovery is deterministic and stops after the first selection:

1. user-specified `VERIFIER_EXECUTABLE`;
2. deployment-supplied `INSTALLED_VERIFIER_EXECUTABLE`;
3. explicit `gh`/`gh.exe` lookup on `PATH`.

Production accepts only a regular absolute path whose executable name is `gh`
or `gh.exe`. The supported version policy is `>=2.49.0,<3.0.0`, followed by
real `gh attestation --help` and `gh attestation verify --help` probes. A tool
outside the range or without both commands is `unsupported`; it is never
silently replaced by another backend. Malformed output, timeout, excessive
output, unsafe paths, and process errors are `error`. No automatic download or
fallback is permitted.

`cmake/check_release_evidence_verifier.cmake` launches the repository-owned
`anosecurekit-verifier-capture` helper for every version, capability, and
verification invocation. The helper passes an exact argument vector to the
backend without a shell. It collects stdout and stderr independently in
anonymous pipes and validates UTF-8 and rejects raw NUL before returning an
ASCII JSON record to CMake. The verification adapter requires the GitHub CLI
JSON format and exactly one verified attestation result.

The default and maximum output limit is 1 MiB per stream (2 MiB combined).
The ASCII bridge is bounded by 12 times the configured per-stream limit plus
128 bytes. The default subprocess deadline is 15 seconds, configurable up to
60. A limit, timeout, malformed transport, or helper error is fail closed.
The helper terminates the Windows job or POSIX process group and limits
inheritance to standard streams. POSIX process groups contain processes that
remain in the group. The backend executable and services running with the
same account or administrative access are within the host trust boundary.

For source builds, build the helper with the Enterprise project or on its
own and supply its absolute canonical path to the existing adapter call:

```sh
cmake -S tools/verifier_capture -B /trusted/build/capture -DCMAKE_BUILD_TYPE=Release
cmake --build /trusted/build/capture --config Release --target anosecurekit-verifier-capture
cmake -DPROBE_ONLY=ON \
  -DVERIFIER_CAPTURE_EXECUTABLE=/trusted/build/capture/anosecurekit-verifier-capture \
  -DVERIFIER_CAPTURE_BUILD_RECEIPT=/trusted/build/capture/receipt-Release.sha256 \
  -P cmake/check_release_evidence_verifier.cmake
```

Use the configuration subdirectory for multi-config builds and the `.exe`
suffix on Windows. The OpenSSL install places the helper and its SHA-256
inventory record alongside the installed adapter. Invoking that adapter selects
the adjacent helper and requires `VERIFIER_CAPTURE_EXPECTED_SHA256` from a
separately trusted installation receipt for the host architecture. The adapter
checks the fixed filename, canonical path, expected digest and protocol. It
does not use the adjacent inventory as an expected identity. The workflow pins
the digest from its controlled build before downloading delivery artifacts.

Build and installation roots must be provisioned by the operator and protected
against writes by untrusted accounts. CMake does not audit host ACLs. The
operator must establish safe directories and receipts before invoking the
adapter. Path checks and hashing precede execution and assume the trusted files
and directories cannot be swapped during invocation. A packaged digest alone
does not establish publisher identity. Do not execute the helper or adapter
from the unverified delivery being checked.

## Trust and identity policy

Verification binds all of these values exactly:

- subject name and SHA-256 digest;
- source repository and owner: `anothel/AnoSecureKit-Enterprise`;
- full 40-character source revision;
- signer workflow:
  `anothel/AnoSecureKit-Enterprise/.github/workflows/anosecurekit-enterprise-ci.yml`;
- SLSA provenance predicate `https://slsa.dev/provenance/v1`;
- GitHub Actions OIDC issuer/trust domain
  `https://token.actions.githubusercontent.com`;
- GitHub-hosted runner identity;
- at least one verified transparency-log or timestamp-authority timestamp;
- immutable local bundle when supplied, otherwise the repository attestation
  API result selected by subject digest.

The GitHub CLI enforces repository, signer workflow, source digest, predicate,
OIDC issuer, hosted runner, signature, certificate, and trusted-root policy.
The adapter then rechecks machine-readable repository, owner, revision,
workflow, trust-domain, subject, digest, and timestamp fields. Multiple results
are ambiguous and rejected.

Trust roots and revocation information come from GitHub CLI's verified Sigstore
TUF trust-root process. Online verification may retrieve the current root and
attestation through GitHub/Sigstore APIs. Offline verification requires an
out-of-band trusted root plus a local bundle; this repository does not pin a
private trust root. Network/API failure is `unavailable`, never `verified`.
Expired release-evidence intervals and revoked evidence remain rejected by the
structural verifier even when a signature verifies.

## Workflow and action supply chain

The CI workflow attests only after downloaded artifact validation succeeds,
and only for `main`/release-tag pushes or explicit `workflow_dispatch`. Fork
pull requests never reach the attestation job; `pull_request_target` is
forbidden. Global permission remains `contents: read`; only the attestation job
adds `id-token: write` and `attestations: write`. Repository secrets are not
used.

`actions/attest` is the official generic GitHub action recommended for new
provenance attestations. It accepts the explicit subject checksum list and
returns the attestation URL and local bundle for the following verification
job. Every action is pinned to a full commit SHA with a nearby human-readable
major-version comment:

- `actions/checkout` v7;
- `actions/upload-artifact` v7;
- `actions/download-artifact` v8;
- `actions/attest` v4;
- `github/codeql-action` v4.

An upgrade must review the upstream release and action source, refresh the full
SHA, run the CI-policy and verifier contract tests, probe the supported `gh`
version on each platform, and complete one hosted attestation plus downstream
verification before the new pin is accepted.

## Platform and test isolation

Windows and POSIX absolute paths are supported. Windows GitHub CLI 2.95.0 is
currently supported and capability-complete. Audited WSL GitHub CLI 2.46.0 has
no attestation command and is `unsupported`; macOS/Linux use the same version
and capability policy.

The fake verifier is `tests/fixtures/fake_release_evidence_verifier.cmake`.
It runs only when both the test script and `ALLOW_TEST_VERIFIER=ON` are explicit.
It is not installed, packaged, auto-selected, or accepted by the customer gate.
Its output cannot become production trusted evidence.

## States and current result

```text
verifier_backend: available | unsupported | unavailable | error
attestation_generation: configured | generated | unavailable | blocked-external
cryptographic_evidence: verified | rejected | unavailable
trusted_evidence: verified | rejected | unavailable
```

The workflow is configured, but no hosted Enterprise attestation currently
exists. Therefore production status remains:

```text
attestation_generation: configured or blocked-external
cryptographic_evidence: unavailable
trusted_evidence: unavailable
release_authorization: denied-or-unavailable
customer_release_ready: false
```
