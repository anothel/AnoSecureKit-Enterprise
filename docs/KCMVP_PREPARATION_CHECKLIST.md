# KCMVP Preparation Checklist

This future-preparation checklist is engineering guidance only. It is not
KCMVP or FIPS validation evidence.

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

Enterprise has an engineering contract for module initialization, self-test
status, operational state, module/build identity, and capability reporting.
The OpenSSL profile and the P3-06 AnoCrypto-C parity adapter test that gate;
mocks retain failure-path coverage. This does not constitute module validation
evidence, and the non-delivery profile remains blocked from customer delivery.
