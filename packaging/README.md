# Packaging

The OpenSSL profile now has a verified install/export/CMake-package path. The
AnoCrypto-C profile remains non-installable until its real adapters and full
capability gates are complete. See `docs/INSTALLATION.md`.

This directory is reserved for private Enterprise packaging work:

- customer binary archives;
- offline installers;
- SBOM generation;
- license notice bundles;
- source-offer bundles for MPL-covered Community files;
- release checksums;
- supported platform packages.

## Delivery manifest policy

`MANIFEST.sha256` is generated inside an immutable release or customer-delivery
directory after all delivered binaries, headers, documentation, licenses,
notices, and package metadata are present. It is not tracked at repository root
and is not authoritative for the mutable Git worktree.

Generate and verify a staged delivery directory:

```sh
cmake -DROOT=/path/to/delivery -P packaging/scripts/generate_manifest.cmake
cmake -DROOT=/path/to/delivery -P packaging/scripts/verify_manifest.cmake
```

Generation writes `/path/to/delivery/MANIFEST.sha256`. Entries use lowercase
SHA-256, two spaces, and normalized relative paths sorted deterministically. The
manifest excludes itself, `.git`, local build directories, IDE metadata, and
temporary files. All other files under the delivery directory are included.

Record the source Git commit or tag and relevant build metadata in the delivery
documentation before generating the manifest. A checksum detects package changes
but does not authenticate the package or its publisher.


## Current package gates

With `BUILD_TESTING=ON` and the bundled OpenSSL profile selected, run:

```sh
cmake --build build --target enterprise-package-check
cmake --build build --target enterprise-delivery-check
```

`enterprise-package-check` verifies the staged Community and Enterprise
installs, required licenses/notices, both CMake package configs, the exported
`anosecurekit::enterprise` target, and an independent installed consumer.

`enterprise-delivery-check` then stages an immutable install, generates and
verifies `MANIFEST.sha256`, creates ZIP/TGZ install archives through a dedicated
CPack project, creates a separate MPL-covered Community source-offer archive,
generates an SPDX 2.3 delivery SBOM and `SHA256SUMS.txt`, extracts every archive,
and checks that private runtime headers, Enterprise implementation sources, and
AnoCrypto-C payloads are absent.
