# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# AnoSecureKit Enterprise Supported Configuration Matrix

Status date: 2026-07-19

`LOCAL_PASS` records local evidence only. `LOCAL_COMPATIBILITY_PASS` records a
test against an unapproved dependency revision and is not package qualification.
`REMOTE_DEFERRED` is not a failure. Every row remains `RELEASE_BLOCKED` for
customer support and release.

| Profile | OS | Architecture | Compiler | Linkage | Community version | OpenSSL version/source | Local status | Hosted status | Customer support status | Evidence |
|---|---|---|---|---|---|---|---|---|---|---|
| openssl | Ubuntu 26.04 under WSL2 | x86-64 | GCC 15.2.0 | Release static | v0.4.0 bundled source | 3.5.5, local system package | `LOCAL_PASS` | `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [Deferred CI status](DEFERRED_CI_STATUS.md#local-verification-completed) |
| openssl | Ubuntu 26.04 under WSL2 | x86-64 | GCC 15.2.0 | Release shared | v0.4.0 bundled source | 3.5.5, local system package | `LOCAL_PASS` | `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [Deferred CI status](DEFERRED_CI_STATUS.md#local-verification-completed) |
| openssl | Ubuntu 26.04 under WSL2 | x86-64 | Clang 21.1.8 | Release static | v0.4.0 bundled source | 3.5.5, local system package | `LOCAL_PASS` | `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [Deferred CI status](DEFERRED_CI_STATUS.md#local-verification-completed) |
| openssl | GitHub Ubuntu runner | Runner architecture not recorded | GCC / Clang | Release static/shared matrix | v0.4.0 bundled source | GitHub runner package | Matching local configurations: `LOCAL_PASS` | `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [Workflow matrix](CI_AND_RELEASE_GATE.md#github-actions-matrix), [deferred checks](DEFERRED_CI_STATUS.md#remote-checks-not-run) |
| openssl | GitHub Windows runner | x86-64 | MSVC | Release shared | v0.4.0 bundled source | vcpkg `openssl:x64-windows` | Not run locally | `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [Workflow matrix](CI_AND_RELEASE_GATE.md#github-actions-matrix), [deferred checks](DEFERRED_CI_STATUS.md#remote-checks-not-run) |
| openssl | GitHub macOS runner | Runner architecture not recorded | AppleClang | Release static | v0.4.0 bundled source | Homebrew `openssl@3` | Not run locally | `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [Workflow matrix](CI_AND_RELEASE_GATE.md#github-actions-matrix), [deferred checks](DEFERRED_CI_STATUS.md#remote-checks-not-run) |
| openssl | GitHub hosted | Not applicable | CodeQL | Not applicable | v0.4.0 | Not applicable | Not applicable | `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [Deferred checks](DEFERRED_CI_STATUS.md#remote-checks-not-run) |
| openssl | GitHub hosted artifacts | Per build matrix | Per build matrix | Per build matrix | v0.4.0 | Per build matrix | Local package verification: `LOCAL_PASS` | Download verification: `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [Deferred checks](DEFERRED_CI_STATUS.md#remote-checks-not-run) |
| openssl | Internal delivery qualification | Not applicable | Not applicable | Not applicable | v0.4.0 | Not applicable | Internal delivery: `LOCAL_PASS` | Signing/provenance: `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [Recovery procedure](DEFERRED_CI_STATUS.md#recovery-procedure) |
| anocrypto-c | Windows | x86-64 | MSVC 19.50 | Release static | v0.4.0 exact bundled source | Development revision `c101c9655f881044c14d8efbc20ea94a2e84f30b` | `LOCAL_COMPATIBILITY_PASS` (`88/88` native; `17/17` Enterprise) | `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [P3-06 checkpoint](ANOCRYPTO_C_P3_06_PARITY_CHECKPOINT.md#validation-record) |
| anocrypto-c | Windows | x86-64 | MSVC 19.50 | Release shared | v0.4.0 exact bundled source | Development revision `c101c9655f881044c14d8efbc20ea94a2e84f30b` | `LOCAL_COMPATIBILITY_PASS` (`88/88` native; `17/17` Enterprise) | `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [P3-06 checkpoint](ANOCRYPTO_C_P3_06_PARITY_CHECKPOINT.md#validation-record) |
| anocrypto-c | Ubuntu 26.04 under WSL2 | x86-64 | GCC 15.2.0 | Release static | v0.4.0 exact bundled source | Development revision `c101c9655f881044c14d8efbc20ea94a2e84f30b` | `LOCAL_COMPATIBILITY_PASS` (`88/88` native; `17/17` Enterprise) | `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [P3-06 checkpoint](ANOCRYPTO_C_P3_06_PARITY_CHECKPOINT.md#validation-record) |
| anocrypto-c | Ubuntu 26.04 under WSL2 | x86-64 | Clang 21.1.8 | Release shared | v0.4.0 exact bundled source | Development revision `c101c9655f881044c14d8efbc20ea94a2e84f30b` | `LOCAL_COMPATIBILITY_PASS` (`88/88` native; `17/17` Enterprise) | `REMOTE_DEFERRED` | `RELEASE_BLOCKED` | [P3-06 checkpoint](ANOCRYPTO_C_P3_06_PARITY_CHECKPOINT.md#validation-record) |

The non-bundled installed-Community path also passed locally, but its complete
compiler/linkage command was not separately recorded in the evidence document;
no additional matrix row or broader support claim is inferred from that result.

## P3-06 qualification baseline

- requested AnoCrypto-C runtime: `0.1.0-p3-05-scrypt-fixed-profile`;
- requested reviewed commit: `89e16a261ab7696d9489167d7403d9f2c704629e`;
- requested source SHA-256:
  `18aa9050a808e4d541b2a6a10e91aa8e51367b95962b90db2183e26377bdbac1`;
- Community revision: `694459ebe497d15ba75ef76a52fa7c36ddd7bcce`;
- required capabilities: all seven;
- OpenSSL fallback: prohibited;
- install/export: disabled;
- hosted status: `NOT_RUN/UNREVIEWED`;
- customer release: `RELEASE_BLOCKED`.

The requested AnoCrypto-C reviewed commit and digest were not available in the
local repository or upstream Git at reintegration time. Compatibility results
against another development revision do not approve or substitute that package.
The development package's Linux installed-package smoke remains blocked because
its exported config references `Threads::Threads` without loading `Threads`.
