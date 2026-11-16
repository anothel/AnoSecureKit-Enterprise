# Scoped engineering reopening — 2026-11-16

The repository owner's modernization requests in this session explicitly reopen
Enterprise engineering for the following bounded work. This record supplements
the historical closeout; it does not activate a customer release or rewrite
historical qualification evidence.

- Product scope: Enterprise-owned provider enforcement, tests/build tooling and
  review delivery. Preserve commits 0131b69 and b7fb7d0 independently.
- Ownership: repository owner authorizes the work and retains merge/release
  decisions; the implementing agent prepares scoped changes and evidence.
- Selected work: reproduce and close provider identity denial bypasses; add
  negative tests; diagnose sanitizer failures; qualify the exact native baseline;
  assess ABI/fuzz/platform gaps; prepare private review branches and PRs.
- Dependency baseline: unmodified Community v0.4.0, tree
  5478a5c37e96aa1017f8f4604234de48c1115d7c. Native reruns use historical Enterprise
  compatibility revision c101c9655f881044c14d8efbc20ea94a2e84f30b and its recorded
  runtime identity; no substitution of a newer archive or source revision.
  c101c965 is compatibility evidence, not a new production provenance approval.
- Verification: actual commands and outcomes, before/after negative tests,
  native lifecycle/primitives/fixtures/no-fallback when obtainable, explicit
  sanitizer/leak/platform limits. Mock execution proves host enforcement only.
- Release boundary: no main merge, releases, release tags, public security claim
  changes, native install/export enablement, or customer distribution. Release
  authorization remains denied-or-unavailable; customer_release_ready: false.
- Community CLI: investigate and recommend an explicit upstream maintenance or
  Enterprise packaging decision; no private patch or baseline update authorized.
- Authorization: current user instructions permit publishing review branches and
  PRs only to the verified private Enterprise repository. Keep vendor source and
  credentials out of public repositories and review logs.

No production support, operational activation, KCMVP/FIPS validation or signing
approval is implied. Further scope changes require an explicit owner decision.
