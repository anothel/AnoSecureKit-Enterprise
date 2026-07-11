# Customer Delivery Pack

A real Enterprise delivery includes more than binaries and must identify its
selected cryptographic-provider profile explicitly.

## Common Contents

- AnoSecureKit Enterprise headers and libraries.
- Enterprise version, source commit/tag, and build metadata.
- AnoSecureKit Community MPL-2.0 notices and source materials as required.
- API reference and integration examples.
- Deployment guide and supported platform/profile matrix.
- Release notes and security-policy limitations.
- SBOM, checksums, and provenance notes.
- Support and vulnerability-reporting contacts.

## OpenSSL Profile Contents

- Clear identification that the product uses the OpenSSL profile.
- Applicable OpenSSL license/notices for any delivered OpenSSL binaries or
  runtime dependencies.
- Verified Community/OpenSSL package and consumer evidence.

## AnoCrypto-C Profile Contents

Only after the profile is implemented, qualified, and separately licensed:

- clear identification of the AnoCrypto-C profile;
- separately supplied AnoCrypto-C package/materials under its contract;
- module version, operational/self-test status, supported capability list, and
  module hash where applicable;
- evidence that the delivered profile has no OpenSSL production fallback;
- exact validation scope only when validation actually exists.

Do not include or promise AnoCrypto-C source or binaries merely because this
repository contains an integration plan.

## Manifest Process

Stage the complete delivery in an immutable directory, record its source Git
commit or tag and build metadata, then generate `MANIFEST.sha256` using the
scripts documented in `packaging/README.md`. Verify the manifest before delivery.
The manifest covers delivered files but does not provide publisher authenticity.
