# Customer Delivery Pack

A real Enterprise delivery should include more than binaries.

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
