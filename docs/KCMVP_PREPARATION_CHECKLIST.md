# KCMVP Preparation Checklist

This scaffold is not KCMVP validated. Use this checklist to keep development
aligned with a future validation effort.

## Module and build boundary

- Define the exact AnoCrypto module boundary.
- Define supported OS, CPU, compiler, and build configuration.
- Record reproducible build inputs and module hashes.
- Separate approved and non-approved modes if applicable.

## Security behavior

- Power-up self-tests.
- Conditional self-tests where required.
- Integrity check.
- Failure state that blocks cryptographic operations.
- Key and CSP lifecycle documentation.
- Zeroization rules and tests.
- Entropy and DRBG design evidence.

## Evidence

- Algorithm known-answer tests.
- Negative tests.
- Fuzzing coverage for parsers/formats.
- API misuse tests.
- Vulnerability analysis.
- Configuration management records.
- Customer security policy document.

## Enterprise runtime gate status

Enterprise now has an engineering contract for module initialization, self-test
status, operational state, module/build identity, and capability reporting.
The OpenSSL profile and mock AnoCrypto-C adapters test the gate. This does not
constitute module validation evidence; the real adapter must map the exact
AnoCrypto-C validated package/API and environment.
