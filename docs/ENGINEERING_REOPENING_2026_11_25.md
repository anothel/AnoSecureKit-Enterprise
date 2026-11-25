# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Scoped internal engineering reopening — 2026-11-25 KST

The repository owner explicitly requested lifting the Enterprise development
freeze on 2026-11-25. The active authorization is recorded in [issue #5](https://github.com/anothel/AnoSecureKit-Enterprise/issues/5#issuecomment-7152217167)
and [issue #6](https://github.com/anothel/AnoSecureKit-Enterprise/issues/6#issuecomment-7152217729).
This decision supersedes the previous engineering freeze for the selected work
below, without changing historical evidence or customer release authority.

- Product: Enterprise 0.1.0, unsupported pre-release/internal qualification.
  Exact reopening baseline: `f1a2c5e08fbe91b3b6a8726f5f846b71cc63c6da`.
- Ownership: owner retains protected-main merge, reserved product changes and
  release authority. Master assigns and verifies; Codex implements and tests
  on isolated branches. Qualified independent human review remains required.
- First work: ASK-3 / #6, exact verifier failure diagnosis and bounded regression
  fixtures for runnerEnvironment cardinality/type and self-hosted rejection.
  Capture sanitized exact verified JSON if available. Preserve fail-closed
  subject, digest, workflow, identity, trust and revocation policies. Production
  verifier/parser changes require separate evidence-backed approval.
- Parallel work: ASK-2/8/9 / #5, actual host/entrypoint, sink and worker ownership
  discovery, lifecycle and authentication/discard acceptance matrix, bounded
  tests of existing contracts. Actual production host verification requires
  actual host evidence. Native Q9 tests require the selected original archive
  and library identity and digest (ACC-29), not a substitute.
- Preserve the official P3-05 SDK pin and exact vendored Community v0.4.0.
  No API/ABI, crypto behavior or production host change without separate scope.
- Verification: exact source and SDK identity, actual commands, OS/compiler,
  configuration, test results, CI links, failure evidence and limits. Linux
  GCC/Clang and existing Windows/macOS profiles where available; unavailable
  runs remain NOT_RUN or BLOCKED. Draft PR only.
- Release boundary: no merge, customer delivery, tag, deployment, release,
  operational activation, support/GA/KCMVP/FIPS claim, native install/export
  enablement, policy weakening, or pin change. Customer release remains false.

Jira ASK is the active execution queue. The pre-GA registry and previous
closeout records are historical evidence; retain them unchanged. This reopening
does not qualify a profile or replace the independent release authorization.
