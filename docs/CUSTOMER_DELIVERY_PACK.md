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

The OpenSSL profile now has two delivery gates:

```sh
cmake --build build --target enterprise-package-check
cmake --build build --target enterprise-delivery-check
```

The second target creates CPack ZIP/TGZ install archives, a separate Community
source-offer archive, `BUILD_METADATA.txt`, an SPDX 2.3 delivery SBOM, and
`SHA256SUMS.txt`. It extracts and verifies the archives and checks that private
provider headers, Enterprise implementation sources, and AnoCrypto-C payloads
are absent.

This is still not a signed release, support agreement, legal approval, or
KCMVP/FIPS validation claim. Checksums detect changes but do not authenticate
the publisher.
