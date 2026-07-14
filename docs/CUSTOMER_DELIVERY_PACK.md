# Customer Delivery Pack

A real Enterprise delivery should include more than binaries. At present, only
the OpenSSL profile has a verified install/export package path. The AnoCrypto-C
profile is explicitly excluded from customer delivery until the real external
module integration and full parity gates pass.

Recommended contents:

- AnoSecureKit Enterprise headers and libraries.
- AnoSecureKit Community MPL-2.0 notices and source-offer/materials as required.
- AnoCrypto materials only when supplied externally under a separate contract.
- SBOM.
- Checksums and provenance notes.
- Security policy.
- Deployment guide.
- Supported platform matrix.
- Release notes.
- API reference.
- Integration examples.
- Support and vulnerability-reporting contacts.

Stage the complete delivery in an immutable directory, record its source Git
commit or tag and build metadata, then generate `MANIFEST.sha256` using the
scripts documented in `packaging/README.md`. Verify the manifest before delivery.
The manifest covers delivered files but does not provide publisher authenticity.


## Current delivery status

The `enterprise-package-check` target verifies the OpenSSL profile's staged
install and independent CMake consumer. This is a package-consumption gate, not
a completed customer archive, installer, SBOM, signature, support agreement, or
legal approval.
