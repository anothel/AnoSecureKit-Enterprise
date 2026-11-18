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
- Authorization: the owner's 2026-11-18 recovery instructions explicitly confirm
  that `anothel/AnoSecureKit-Enterprise` is intentionally public and authorize
  public GitHub development and CI on the existing review branches. This
  supersedes the earlier private-review restriction. Keep credentials out of
  commits and logs; external native dependency source remains outside this repo.

Recovery on 2026-11-18 independently reconstructs unavailable local commit
`6a9b314`: no bundle, patch or original commit object was available, so the new
commit SHA differs. The unknown-commit exception is limited to single-config
Debug native testing. Regressions cover active stream continuation, recovery
with valid authentication tags, and real native shutdown. Customer release
authorization remains blocked.

No production support, operational activation, KCMVP/FIPS validation or signing
approval is implied. Further scope changes require an explicit owner decision.
