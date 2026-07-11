# AnoCrypto Integration Plan

AnoCrypto integration should be done as a real backend, not as a marketing
placeholder.

## Minimum integration gate

1. Stable C99 API and ABI policy.
2. Externally supplied CMake package or source tree outside this repository.
3. Known-answer tests for each algorithm.
4. Differential tests against OpenSSL-backed Community behavior where applicable.
5. Format compatibility fixtures for Enterprise packet/file formats.
6. Self-test and failure-state behavior.
7. Module-boundary, key-lifecycle, and security-policy documents.
8. Private/commercial license terms.
9. Customer distribution packaging and notices.

## Expected CMake direction

```sh
-DANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO=ON
-DANOCRYPTO_ROOT=/path/to/anocrypto
```

The first implementation should be limited to a small compatibility surface:
randomness, SHA-2, HMAC, KDF, AEAD/file sealing primitives, and self-test status.
AnoCrypto source, headers, binaries, and package contents must remain outside
this repository.
