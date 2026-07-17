# AnoCrypto-C Upstream Requirements

This queue is for the separate AnoCrypto-C project. Enterprise must consume
public packaged APIs; it must not implement these primitives itself.

1. **HKDF-SHA-256 public C API and tests**
   - SHA-256 extract-and-expand; explicit empty input/salt/info and 0..8160-byte
     output rules; no partial output on failure.
   - RFC 5869 KATs, limit tests, and the exact
     `anosecurekit file sealing v1` compatibility case.

2. **AES-256-GCM one-shot API and KATs**
   - Fixed 32-byte key, 12-byte nonce, 16-byte tag; arbitrary AAD; empty
     plaintext; authenticated output only.
   - NIST KATs, corrupt-input tests, length validation, and whole-output clearing.

3. **AES-256-GCM streaming API and state tests**
   - Encrypt/decrypt init, AAD-before-data, update, finalize/tag, shutdown, and
     explicit invalid state transitions.
   - Split-update parity and authentication-failure tests defining ownership and
     handling of plaintext emitted before finalize.

4. **scrypt or approved password-KDF decision**
   - To preserve `SKP1` v1: support `N=32768`, `r=8`, `p=1`, 32-byte salt,
     32-byte output, and a 64 MiB limit with overflow-safe validation and KATs.
   - Any replacement KDF requires a product/format-version decision; it cannot
     silently replace v1 scrypt.

5. **Key-wrap compatibility decision**
   - Current Community wrapping is a 32-byte key inside `SKT1` AES-256-GCM, not
     AES-KW/KWP. Reuse the GCM APIs for compatibility or define a new version;
     do not substitute another primitive under `SKT1` v1.

6. **Installed package and ABI updates**
   - Add public headers/symbols, exported CMake target usage requirements,
     symbol visibility, version/build identity, ABI documentation, changelog,
     static/shared Linux packages, and reproducible package hashes.

7. **Enterprise integration evidence**
   - OpenSSL/AnoCrypto-C parity for public APIs and all `SKT1`/`SKF1`/`SKP1`
     fixtures; negative/error/output-clearing tests; `ldd` proof without
     `libcrypto`/`libssl`; GCC/Clang static/shared results; package provenance.

Completion of this queue is necessary but does not itself make the Enterprise
AnoCrypto-C profile production-ready, validated, certified, or deliverable.
