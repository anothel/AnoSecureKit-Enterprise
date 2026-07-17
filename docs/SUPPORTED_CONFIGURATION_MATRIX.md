# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# AnoSecureKit Enterprise Supported Configuration Matrix

Status date: 2026-07-17

`LOCAL_PASS` records local evidence only. `REMOTE_DEFERRED` is not a failure.
Every row remains `RELEASE_BLOCKED` for customer support and release.

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

The non-bundled installed-Community path also passed locally, but its complete
compiler/linkage command was not separately recorded in the evidence document;
no additional matrix row or broader support claim is inferred from that result.
