# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# OpenSSL Profile GA Path

This sequence applies only to the OpenSSL profile. Each step requires the named
registry blockers to be closed with exact evidence; step completion never
implies a later step.

| Step | Required evidence | Responsible owner | Registry blockers |
|---|---|---|---|
| 1. Current clean source revision | reviewed exact Git revision, clean tree, Community tree binding | `product-owner` | registry binding |
| 2. Local Windows/WSL qualification | clean Release builds, complete CTest, preflight, package/consumer results | `product-owner` | `PGA-OSSL-LOCAL-WINDOWS`, `PGA-OSSL-LOCAL-WSL` |
| 3. Hosted OS/compiler qualification | required Ubuntu, Windows, macOS, sanitizer, and non-bundled lanes at one revision | `product-owner` | `PGA-OSSL-HOSTED-UBUNTU`, `PGA-OSSL-HOSTED-WINDOWS`, `PGA-OSSL-HOSTED-MACOS` |
| 4. CodeQL | required CodeQL C/C++ PASS bound to revision | `evidence-reviewer` | `PGA-OSSL-CODEQL` |
| 5. Hosted artifact verification | generated and downloaded set with manifest, checksum, SBOM, metadata, license/source offer verification | `product-owner`, `evidence-reviewer` | `PGA-OSSL-HOSTED-ARTIFACT-GENERATION`, `PGA-OSSL-HOSTED-ARTIFACT-DOWNLOAD` |
| 6. Attestation generation and cryptographic verification | actual bundle plus approved verifier PASS for subject/repository/revision/workflow/trust domain | `evidence-reviewer` | `PGA-OSSL-ATTESTATION-GENERATION`, `PGA-OSSL-ATTESTATION-CRYPTO-VERIFY` |
| 7. Trusted evidence record | canonical verified record for exact revision and artifact set | `evidence-reviewer` | `PGA-OSSL-TRUSTED-EVIDENCE-CURRENT-REVISION` |
| 8. Operational owner/channel decision | non-personal roles, private intake decision, and qualified systems or explicit waiver | `product-owner`, `security-intake-owner` | `PGA-OSSL-PRIVATE-REPORTING-DECISION`, `PGA-OSSL-OPERATIONAL-ROLE-ASSIGNMENT`, `PGA-OSSL-SECURITY-SYSTEM-DECISION-OR-WAIVER` |
| 9. Release authorization | active, unexpired, separately approved record bound to trusted evidence and exact artifacts | `release-authorizer` | `PGA-OSSL-RELEASE-AUTHORIZATION-ARTIFACT-SET` |
| 10. Customer package verification | final customer candidate rechecked against manifest, evidence, and authorization | `product-owner`, `evidence-reviewer` | customer delivery gate |
| 11. Support-state transition approval | approved move from unsupported for exact version after every prior step | `product-owner` | `PGA-OSSL-SUPPORT-STATE-APPROVAL` |

Current stop point: step 3. Steps 1-2 have local evidence; hosted qualification
is not passed and remains `BLOCKED_EXTERNAL`. Local PASS does not substitute.

```text
trusted evidence: unavailable
release authorization: denied-or-unavailable
customer_release_ready: false
```
