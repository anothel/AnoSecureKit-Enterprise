# AnoCrypto-C Parity Gaps

This records the remaining gap between the bundled, unmodified AnoSecureKit
Community v0.4.0 backend contract and the Enterprise AnoCrypto-C development
profile. It is an integration contract, not approval to implement primitives in
Enterprise.

```text
Enterprise OpenSSL profile
= current complete Community functionality

Enterprise AnoCrypto-C development profile
= lifecycle + SHA-256 + HMAC-SHA-256 + random

Enterprise AnoCrypto-C production profile
= blocked
```

The development profile is not production-ready, validated, certified, or
customer-deliverable. Its exact capability mask is
`sha256 hmac-sha256 random`. Installation, CMake export, CPack, delivery
ZIP/TGZ, delivery SBOM, signing, and attestation remain blocked.

## Community v0.4.0 contract inspected

The baseline is release commit `102965bee601f2adfb1b624e8425d1c95aaa8c8d`
and Git tree `9b498f5431f217ac71e8d2e2c92df9e8b0122626`. Relevant sources are:

- `src/backend/crypto_backend.hpp` and `crypto_backend_openssl.cpp`;
- `src/aead.cpp`, `src/packet_stream.cpp`, and `src/key_wrap.cpp`;
- `src/file.cpp`, `src/file_crypto.cpp`, and `src/file_detail.hpp`;
- `docs/FORMAT.md` and the v1 compatibility fixtures.

## Gap matrix

| Missing area | Community operations | Serialized formats | New AnoCrypto-C API? | v1 compatibility |
|---|---|---|---|---|
| HKDF-SHA-256 | public `hkdf_sha256`; raw-key file key derivation | `SKF1` | Yes | Yes, with exact SHA-256 semantics and context bytes |
| scrypt | password file key derivation | `SKP1` | Yes, unless an approved decision keeps scrypt unavailable | Yes only with exact v1 scrypt parameters |
| AES-256-GCM one-shot | file chunks; backend encrypt/decrypt | `SKF1`, `SKP1` | Yes | Yes, with exact nonce/tag/AAD behavior |
| AES-256-GCM streaming | `encrypt`, `decrypt`, `packet_encryptor`, `packet_decryptor` | `SKT1` | Yes | Yes, with the existing state and output contract |
| Key wrapping | `wrap_key`, `unwrap_key` | `SKT1` | No separate wrap primitive is required | Yes; it is existing SKT1 AES-256-GCM, not AES-KW |

## HKDF-SHA-256

Community requires RFC 5869 extract-and-expand with SHA-256. The public API
accepts arbitrary byte spans for input key material, salt, and info and derives
exactly the requested byte count. Empty input key material is valid. Empty salt
has RFC 5869 meaning (a HashLen-sized all-zero salt), empty info is valid, and a
zero output request returns an empty vector without invoking a provider.

SHA-256 permits at most `255 * 32 = 8160` output bytes. The current OpenSSL
provider delegates that limit to `EVP_KDF_derive`; provider rejection becomes
the stable public `error_code::backend_failure`. The upstream contract needs an
explicit maximum and must never return a truncated or partially valid output.

`SKF1` derives its 32-byte file key from the caller's 32-byte master key, the
header's 32-byte salt, and the exact info bytes
`anosecurekit file sealing v1`. Changing that label, its encoding, digest,
extract/expand mode, or salt handling breaks existing files.

Required evidence:

- RFC 5869 cases already used by Community, including empty salt/info and empty
  key material;
- output sizes 0, 1, 32, 8160, and rejection at 8161;
- exact `SKF1` known-file fixture decryption and OpenSSL/AnoCrypto-C parity;
- error mapping and whole-output clearing for every upstream failure.

A public AnoCrypto-C HKDF-SHA-256 API is required. Existing `SKF1` remains
compatible if the semantics above are byte-for-byte identical.

## scrypt

Community uses scrypt only for `SKP1` password sealing. Password bytes are used
exactly as supplied and must be non-empty. The 64-byte v1 header stores unsigned
big-endian 32-bit `N`, `r`, and `p` values at offsets 52, 56, and 60. v1 accepts
only:

```text
N = 32768
r = 8
p = 1
maxmem = 64 MiB (runtime policy, not serialized)
output = 32 bytes
salt = 32 header bytes
```

The API contract must validate `N` as a power of two greater than one, reject
zero or overflowing `r`/`p`, perform overflow-safe cost calculations, and honor
the caller's memory ceiling before allocation. Invalid parameters and resource
exhaustion must fail without a derived key; the current public boundary reports
provider failure as `error_code::backend_failure` and clears the 32-byte key on
failure.

Required evidence:

- deterministic RFC 7914 or equivalent KATs plus the exact Community v1 tuple;
- lower/upper parameter, integer-overflow, and memory-limit rejection tests;
- `SKP1` known-password fixture compatibility and wrong-password behavior;
- no key output on invalid, allocation, or resource failures.

A public scrypt API is required unless the upstream/product decision is to keep
`SKP1` unsupported. Replacing scrypt with another KDF cannot read or reproduce
existing `SKP1` v1 files and therefore requires a new format/version decision.

## AES-256-GCM one-shot

Community file encryption requires a 32-byte key, 12-byte nonce, and 16-byte
tag. AAD is an arbitrary byte span and may be empty. Empty plaintext is valid:
encryption returns empty ciphertext plus a tag, and authenticated decryption
returns empty plaintext. Ciphertext length equals plaintext length.

For every `SKF1` or `SKP1` chunk, the nonce is the 8-byte header nonce prefix
followed by the big-endian 32-bit chunk index. AAD is the complete serialized
file header, then the 9-byte record header, then caller AAD. Any tag, key,
nonce, header, record, ciphertext, or AAD mismatch must fail authentication.
One-shot decryption must not return plaintext before tag verification and must
clear all temporary plaintext on failure. Community maps tag failure to the
generic public `error_code::authentication_failed` / `File authentication
failed`; backend setup or operation failure remains `backend_failure`.

Required evidence:

- NIST AES-256-GCM KATs covering empty/non-empty plaintext and empty/non-empty
  AAD;
- exact key/nonce/tag length rejection and in-place/overlap rules;
- corrupted key, nonce, AAD, ciphertext, and tag cases with cleared output;
- all `SKF1`/`SKP1` known and negative fixtures through both providers.

A public AnoCrypto-C one-shot AES-256-GCM API is required. Existing v1 formats
remain compatible if these byte and failure semantics are preserved.

## Streaming AEAD

Community's `SKT1` packet APIs require separate encrypt and decrypt contexts.
Initialization binds the 32-byte key and 12-byte nonce. AAD updates occur before
payload updates and in this exact order: the 5-byte `SKT1` header, then caller
AAD. Payload may be supplied in multiple updates. Encrypt finalization returns
the 16-byte tag; decrypt finalization consumes it and authenticates the stream.
Repeated begin/finalize, update before begin, update after finalize, wrong tag
length, moved-from state, and AAD after payload must have defined state errors.

The current low-level decrypt update can emit explicitly **unverified**
plaintext before final authentication. `anosecurekit::decrypt` buffers that
plaintext and securely wipes it when finalize fails. Callers of
`packet_decryptor` own the documented rule not to release, persist, or trust
update output before successful finalize. Path-based file open uses temporary
output and commits only after all chunks authenticate; stream file open cannot
roll back caller-owned output.

Required evidence:

- chunk-split parity, zero-length updates, AAD ordering, and complete state
  transition tests;
- finalize success/failure and repeated-operation tests;
- wrong key/AAD/ciphertext/tag tests proving buffered output rollback or wipe;
- `SKT1` known fixtures and one-shot/streaming cross-compatibility.

A public AnoCrypto-C streaming AES-256-GCM API is required. If upstream cannot
guarantee safe caller-managed unverified output, Enterprise must add buffering
at integration time without changing `SKT1` bytes or public error behavior.

## Key wrapping

Community does not use AES Key Wrap, AES-KWP, or an AnoCrypto key-handle wrap
operation. `wrap_key` encrypts the 32 raw key bytes with the existing public
`encrypt` API and the caller's 32-byte wrapping key. `unwrap_key` decrypts the
same `SKT1` packet, requires exactly 32 plaintext bytes, and wipes the temporary
key bytes. AAD is passed through unchanged.

Required evidence is the existing `skt1-key-wrap` and `skt1-key-wrap-zero`
fixtures, wrong wrapping key/AAD, malformed packet, wrong recovered length, and
temporary-key clearing. A separate AnoCrypto-C key-wrap API is not required if
the one-shot/streaming AES-256-GCM APIs reproduce current `SKT1` behavior.
Choosing a new wrapping algorithm would be a new format, not v1 compatibility.

## Fail-closed integration rule

Until every required API and test above exists, the development provider must
keep HKDF-SHA-256, scrypt, AES-256-GCM, streaming AEAD, and key wrapping absent
from its mask. Public calls must throw the existing backend failure, return no
fake or partial output, never link or call the Community OpenSSL provider, and
never commit a failed path-based file output. Complete-profile readiness stays
false.
