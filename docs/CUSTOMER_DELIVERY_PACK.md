# Customer Delivery Pack

A real Enterprise delivery should include more than binaries. At present, only
the OpenSSL profile has a verified install/export package path. The AnoCrypto-C
profile is explicitly excluded from customer delivery until approved package
provenance, full capability parity, and all release gates pass.

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

Customer delivery additionally requires an external authorization record that
passes `enterprise-release-authorization-check`. The record must bind the exact
source revision, versions, Community tree, backend/provider family, staged
manifest, complete artifact set, hosted qualification, CodeQL policy, signing,
provenance, approver role, and validity window. Current authorization is denied
or unavailable; `customer_release_ready` remains `false`. Production allow is
also hard-disabled until trusted hosted, signing, and provenance evidence
verification exists.

The canonical evidence bundle and its structural, cryptographic, and trusted
state model are defined in `TRUSTED_RELEASE_EVIDENCE_POLICY.md`. The current
cryptographic verifier is unavailable, so the bundle cannot authorize a
production delivery.


## Continuous verification

`enterprise-release-preflight` combines profile, runtime, test, installed-consumer,
delivery, and CI-policy checks. The private CI matrix is configured to run this
gate across its build environments; hosted execution remains deferred. Uploaded
workflow artifacts are internal evidence and remain unsigned and unapproved for
customer delivery.
