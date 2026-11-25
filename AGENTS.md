# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Repository agent instructions

Read [current status](docs/CURRENT_STATUS.md), [change policy](docs/DEVELOPMENT_FREEZE_AND_CHANGE_POLICY.md)
and [scoped reopening](docs/ENGINEERING_REOPENING_2026_11_25.md). The latest applicable owner authorization
on the existing issue governs scope. Preserve all security and release gates,
exact Community and SDK pins, and independent human review requirements.

## Codex result handoff

- Before starting or resuming, read the existing issue and latest authorization,
  check the exact baseline and existing branches/PRs. Do not duplicate active work.
- Use an isolated branch/worktree; implement/test only the authorized scope.
- Record every outcome (including BLOCKED and read-only tasks) on the existing
  GitHub issue or PR: task ID, status, base/head, files/commits, commands and
  actual test results, CI/Draft PR links, blockers and next action. Link Jira
  rather than duplicating full evidence. Use sanitized evidence and approved
  private channels for sensitive details; never publish secrets or customer data.
- If publication is unavailable, report the exact blocker without bypassing
  controls. No fabricated evidence, automatic merge, release, or gate weakening.
  Master verifies the result; Codex does not impersonate human reviewers.
