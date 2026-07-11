# KCMVP Preparation Checklist

AnoSecureKit Enterprise and AnoCrypto-C are not claimed to be KCMVP validated.
Use this checklist to keep a future AnoCrypto-C-backed Enterprise profile aligned
with a possible validation effort.

Validation cannot be inferred from the product name. The exact AnoCrypto-C
module version, build, operating environment, approved mode, and Enterprise
integration configuration must fall within the validated scope.

## Module and Build Boundary

- Define the exact external AnoCrypto-C module boundary.
- Define the proprietary Enterprise adapter boundary separately.
- Define supported OS, CPU, compiler, and build configuration.
- Record reproducible build inputs and module hashes.
- Separate approved and non-approved modes if applicable.
- Prove that the AnoCrypto-C profile has no unintended OpenSSL production
  dependency or fallback.
- Record package, target, module version, and selected Enterprise profile.

## Security Behavior

- Power-up self-tests.
- Conditional self-tests where required.
- Integrity check.
- Failure state that blocks cryptographic operations.
- Key and CSP lifecycle documentation.
- Zeroization rules and tests.
- Entropy and DRBG design evidence.
- Capability gate that rejects unavailable required services.

## AnoSecureKit Integration Evidence

- Common public API tests executed against the AnoCrypto-C profile.
- Known-answer and negative tests for the adapter boundary.
- `SKT1`/`SKF1`/`SKP1` compatibility evidence, or a new versioned format when
  validated algorithms/policies differ.
- Authentication-failure and output commit/rollback tests.
- Provider identity, self-test, and operational-state diagnostics.
- Installed package and customer consumer tests.

## Evidence and Governance

- Algorithm known-answer tests.
- Negative tests.
- Fuzzing coverage for parsers/formats.
- API misuse tests.
- Vulnerability analysis.
- Configuration management records.
- Customer security policy document.
- License, redistribution, SBOM, checksum, provenance, and support review.
