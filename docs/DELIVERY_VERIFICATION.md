# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# OpenSSL Profile Delivery Verification

The verified Enterprise OpenSSL customer-delivery staging directory contains:

- ZIP and TGZ install archives created through CPack;
- a separate AnoSecureKit Community v0.4.0 source-offer archive;
- `LICENSE` and `THIRD_PARTY_NOTICES.md`;
- `BUILD_METADATA.txt`;
- an SPDX 2.3 delivery SBOM;
- `SHA256SUMS.txt` covering every top-level delivery asset except itself.

Generate and verify the staged delivery with:

```sh
cmake --build build --target enterprise-delivery-check
```

The target verifies both binary archives by extraction, confirms that Community
and Enterprise CMake packages and public headers are present, checks that private
runtime-contract headers and Enterprise implementation sources are absent, and
verifies the independent MPL-covered Community source-offer archive.

`SHA256SUMS.txt` and the directory `MANIFEST.sha256` detect modifications. They
do not authenticate the publisher. Production delivery still requires a
separate signing/provenance process and legal/security approval.

The incomplete AnoCrypto-C profile has no install/export/CPack path and cannot
produce this delivery.
